#!/bin/bash
#
# install.sh - set up this machine from the dotfiles repo.
#
#   ./install.sh              run every step
#   ./install.sh packages     Homebrew + Brewfile only
#   ./install.sh links        symlinks only
#   ./install.sh plugins      sheldon + tmux plugins only
#
# Steps can be combined: ./install.sh links plugins
# The script is idempotent - safe to run as often as you like.
#
# What it reads:
#   Brewfile                 packages (brew bundle)
#   */links.prop             symlinks, one "src=dst" per line (all OSes)
#   */links.<os>.prop        symlinks for one OS only (darwin | linux)
#
# When a destination already exists (DOTFILES_ON_CONFLICT=backup|overwrite|skip):
#   - interactive terminal: asks
#   - no terminal (CI, curl | bash): backs it up, never silently skips
#
# Exit status is non-zero if any step failed, but one failure no longer aborts
# the others; they are all reported at the end.

set -u

cd "$(dirname "$0")" || exit 1
DOTFILES=$(pwd -P)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
FAILURES=()

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------
info() { printf "\r  [ \033[00;34m..\033[0m ] %s\n" "$1"; }
user() { printf "\r  [ \033[0;33m??\033[0m ] %s\n" "$1" >&2; }
success() { printf "\r\033[2K  [ \033[00;32mOK\033[0m ] %s\n" "$1"; }
fail() {
	printf "\r\033[2K  [\033[0;31mFAIL\033[0m] %s\n" "$1"
	FAILURES+=("$1")
}

# ---------------------------------------------------------------------------
# Homebrew + packages
# ---------------------------------------------------------------------------
brew_shellenv() {
	local brew_path
	for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
		if [[ -x "$brew_path" ]]; then
			eval "$("$brew_path" shellenv)"
			return 0
		fi
	done
	return 1
}

ensure_brew() {
	command -v brew &>/dev/null && return 0
	brew_shellenv && return 0
	info "Homebrew not found. Installing Homebrew..."
	NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || return 1
	brew_shellenv
}

install_packages() {
	info "Installing packages from Brewfile..."
	if ! ensure_brew; then
		fail "Homebrew is not available"
		return
	fi
	# --no-upgrade: only install what is missing, like a re-run should
	if brew bundle --no-upgrade --file="$DOTFILES/Brewfile"; then
		success "Brewfile satisfied"
	else
		fail "brew bundle reported errors (see output above)"
	fi
}

# ---------------------------------------------------------------------------
# Symlinks
# ---------------------------------------------------------------------------
# CONFLICT_POLICY: ask | backup | overwrite | skip
can_prompt() { { : </dev/tty; } 2>/dev/null; }

CONFLICT_POLICY=${DOTFILES_ON_CONFLICT:-}
if [[ -z "$CONFLICT_POLICY" ]]; then
	# legacy switches, kept for the Dockerfile and old habits
	if [[ "${DOTFILES_OVERWRITE_ALL:-false}" == true ]]; then
		CONFLICT_POLICY=overwrite
	elif [[ "${DOTFILES_BACKUP_ALL:-false}" == true ]]; then
		CONFLICT_POLICY=backup
	elif [[ "${DOTFILES_SKIP_ALL:-false}" == true ]]; then
		CONFLICT_POLICY=skip
	elif can_prompt; then
		CONFLICT_POLICY=ask
	else
		CONFLICT_POLICY=backup
	fi
fi

# Sets CHOICE to backup | overwrite | skip for the given destination.
resolve_conflict() {
	local dst=$1 answer
	CHOICE=$CONFLICT_POLICY
	[[ "$CONFLICT_POLICY" == ask ]] || return 0

	user "$dst already exists. [b]ackup, [o]verwrite, [s]kip (capital letter = apply to all)?"
	read -r -n 1 answer </dev/tty
	echo >&2
	case "$answer" in
	b) CHOICE=backup ;;
	o) CHOICE=overwrite ;;
	B) CHOICE=backup CONFLICT_POLICY=backup ;;
	O) CHOICE=overwrite CONFLICT_POLICY=overwrite ;;
	S) CHOICE=skip CONFLICT_POLICY=skip ;;
	*) CHOICE=skip ;;
	esac
}

link_file() {
	local src=$1 dst=$2

	if [[ ! -e "$src" ]]; then
		fail "link source missing: $src"
		return
	fi

	if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
		success "already linked: $dst"
		return
	fi

	if [[ -e "$dst" || -L "$dst" ]]; then
		resolve_conflict "$dst"
		case "$CHOICE" in
		overwrite)
			rm -rf "$dst"
			info "removed $dst"
			;;
		backup)
			local backup
			backup="$dst.backup.$(date +%Y%m%d-%H%M%S)"
			mv "$dst" "$backup"
			info "moved $dst to $backup"
			;;
		*)
			info "skipped $dst"
			return
			;;
		esac
	fi

	mkdir -p "$(dirname "$dst")"
	if ln -s "$src" "$dst"; then
		success "linked $dst -> $src"
	else
		fail "could not link $dst"
	fi
}

install_links() {
	info "Linking dotfiles..."
	local linkfile line src dst
	while IFS= read -r linkfile; do
		info "Processing ${linkfile#"$DOTFILES"/}"
		while IFS= read -r line || [[ -n "$line" ]]; do
			[[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
			src=${line%%=*}
			dst=${line#*=}
			# expand the two variables we support, without eval
			src=${src//\$DOTFILES/$DOTFILES}
			src=${src//\$HOME/$HOME}
			dst=${dst//\$DOTFILES/$DOTFILES}
			dst=${dst//\$HOME/$HOME}
			link_file "$src" "$dst"
		done <"$linkfile"
	done < <(find "$DOTFILES" -maxdepth 2 \( -name links.prop -o -name "links.$OS.prop" \) -not -path '*/.git/*' | sort)
}

# ---------------------------------------------------------------------------
# Plugins (sheldon, tmux)
# ---------------------------------------------------------------------------
setup_sheldon() {
	if ! command -v sheldon &>/dev/null; then
		fail "sheldon is not installed (run: ./install.sh packages)"
		return
	fi
	info "Installing sheldon plugins..."
	if sheldon lock; then
		success "sheldon plugins installed"
	else
		fail "sheldon lock failed"
	fi
}

setup_tmux() {
	local tpm_dir="$HOME/.tmux/plugins/tpm"

	if ! command -v tmux &>/dev/null; then
		fail "tmux is not installed (run: ./install.sh packages)"
		return
	fi

	if [[ -d "$tpm_dir" ]]; then
		success "TPM is already installed"
	elif git clone --quiet https://github.com/tmux-plugins/tpm "$tpm_dir"; then
		success "TPM installed"
	else
		fail "could not clone TPM"
		return
	fi

	info "Installing tmux plugins..."
	tmux new-session -d -s tpm_install 2>/dev/null || true
	if "$tpm_dir/bin/install_plugins"; then
		success "tmux plugins installed"
	else
		fail "tmux plugin install failed"
	fi
	tmux kill-session -t tpm_install 2>/dev/null || true
}

install_plugins() {
	setup_sheldon
	setup_tmux
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
usage() {
	sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
}

main() {
	local steps=("$@") step
	[[ ${#steps[@]} -gt 0 ]] || steps=(packages links plugins)

	for step in "${steps[@]}"; do
		case "$step" in
		-h | --help | help)
			usage
			exit 0
			;;
		packages | links | plugins) ;;
		*)
			echo "unknown step: $step (expected: packages, links, plugins)" >&2
			exit 2
			;;
		esac
	done

	echo ""
	info "Dotfiles: $DOTFILES ($OS), steps: ${steps[*]}, on conflict: $CONFLICT_POLICY"
	echo ""

	for step in "${steps[@]}"; do
		case "$step" in
		packages) install_packages ;;
		links) install_links ;;
		plugins)
			# plugins need brew-installed tools on PATH
			ensure_brew || true
			install_plugins
			;;
		esac
		echo ""
	done

	if [[ ${#FAILURES[@]} -gt 0 ]]; then
		fail "${#FAILURES[@]} step(s) failed:"
		printf '         - %s\n' "${FAILURES[@]}"
		exit 1
	fi

	success "Done."
	info "Open a new terminal (or run 'source ~/.zshrc'). For neovim, run 'nvim' once to let LazyVim install plugins."
}

main "$@"
