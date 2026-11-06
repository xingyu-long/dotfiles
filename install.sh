#!/bin/bash
#
# install.sh - set up this machine from the dotfiles repo.
#
#   ./install.sh                  run every step, one summary line per step
#   ./install.sh -v               also show every detail and the tools' own output
#   ./install.sh -n               dry run: show what would change, change nothing
#   ./install.sh links            run one step (packages | links | plugins)
#   ./install.sh -n links plugins steps and flags can be combined
#
# Steps:
#   packages   Homebrew + everything in the Brewfile (missing packages only)
#   links      symlinks from */links.prop and */links.<darwin|linux>.prop
#   plugins    sheldon plugins, TPM and the tmux plugins
#
# When a link destination already exists (DOTFILES_ON_CONFLICT=backup|overwrite|skip):
#   - interactive terminal: asks
#   - no terminal (CI, curl | bash): backs it up, never silently skips
#
# The script is idempotent. A failing step does not abort the others; every
# failure is listed at the end and the exit status is non-zero. Output goes to
# a log per step (kept only when something fails). NO_COLOR disables colors.

set -u

cd "$(dirname "$0")" || exit 1
DOTFILES=$(pwd -P)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

VERBOSE=false
DRY_RUN=false
FAILURES=()
LOG_DIR=
STEP_NAME=
STEP_LOG=/dev/null
SUMMARY=
N_FAILED=0
LAST_FAIL=

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
	TTY=true
	RED=$'\033[31m'
	GREEN=$'\033[32m'
	YELLOW=$'\033[33m'
	DIM=$'\033[2m'
	RESET=$'\033[0m'
else
	TTY=false
	RED=
	GREEN=
	YELLOW=
	DIM=
	RESET=
fi

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------
# say: a detail line. Shown with -v, otherwise only written to the step log.
say() {
	if $VERBOSE; then
		printf '  %s\n' "$1"
	else
		printf '%s\n' "$1" >>"$STEP_LOG"
	fi
}

# run: run a command; its output is shown with -v, otherwise logged.
run() {
	if $VERBOSE; then
		"$@"
	else
		"$@" >>"$STEP_LOG" 2>&1
	fi
}

# bad: record a failure for the current step.
bad() {
	N_FAILED=$((N_FAILED + 1))
	LAST_FAIL=$1
	FAILURES+=("$STEP_NAME: $1")
	say "${RED}FAIL${RESET} $1"
}

# join_parts "a" "" "b" -> "a, b" (empty parts are skipped)
join_parts() {
	local out="" part
	for part in "$@"; do
		[[ -n "$part" ]] || continue
		out="${out:+$out, }$part"
	done
	printf '%s' "$out"
}

# ---------------------------------------------------------------------------
# Step: packages
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

step_packages() {
	if ! command -v brew &>/dev/null && ! brew_shellenv; then
		if $DRY_RUN; then
			SUMMARY="would install Homebrew and every Brewfile package"
			return
		fi
		say "Installing Homebrew..."
		if ! run env NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || ! brew_shellenv; then
			bad "could not install Homebrew"
			SUMMARY="Homebrew install failed"
			return
		fi
	fi

	local brewfile="$DOTFILES/Brewfile" total missing names
	total=$(($(brew bundle list --file="$brewfile" --formula | wc -l) + $(brew bundle list --file="$brewfile" --cask | wc -l)))
	# --no-upgrade: outdated packages count as installed
	names=$(brew bundle check --no-upgrade --verbose --file="$brewfile" 2>&1 | sed -n -E 's/.*(Formula|Cask) ([^ ]+) needs to be installed.*/\2/p' | tr '\n' ' ')
	missing=$(wc -w <<<"$names" | tr -d ' ')

	if [[ "$missing" -eq 0 ]]; then
		say "Brewfile already satisfied ($total entries)"
		SUMMARY="$total present, nothing to install"
	elif $DRY_RUN; then
		say "would install: $names"
		SUMMARY="$((total - missing)) present, would install $missing: ${names% }"
	elif run brew bundle --no-upgrade --file="$brewfile"; then
		SUMMARY="$((total - missing)) present, $missing installed: ${names% }"
	else
		bad "brew bundle reported errors"
		SUMMARY="brew bundle failed"
	fi
}

# ---------------------------------------------------------------------------
# Step: links
# ---------------------------------------------------------------------------
can_prompt() { { : </dev/tty; } 2>/dev/null; }

# CONFLICT_POLICY: ask | backup | overwrite | skip
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

# Sets CHOICE to backup | overwrite | skip | ask for the given destination.
resolve_conflict() {
	local dst=$1 answer
	CHOICE=$CONFLICT_POLICY
	[[ "$CONFLICT_POLICY" == ask ]] || return 0
	$DRY_RUN && return 0 # never prompt in a dry run

	printf '\r\033[2K  %s?%s %s already exists. [b]ackup, [o]verwrite, [s]kip (capital letter = apply to all)? ' "$YELLOW" "$RESET" "$dst" >&2
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

L_OK=0 L_LINKED=0 L_BACKUP=0 L_OVERWRITE=0 L_SKIP=0 L_ASK=0

link_file() {
	local src=$1 dst=$2 backup

	if [[ ! -e "$src" ]]; then
		bad "link source missing: $src"
		return
	fi

	if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
		say "already linked: $dst"
		L_OK=$((L_OK + 1))
		return
	fi

	if [[ -e "$dst" || -L "$dst" ]]; then
		resolve_conflict "$dst"
		case "$CHOICE" in
		ask)
			say "$dst exists: would ask what to do"
			L_ASK=$((L_ASK + 1))
			return
			;;
		overwrite)
			if $DRY_RUN; then
				say "would overwrite: $dst"
			else
				rm -rf "$dst"
				say "overwrote $dst"
			fi
			L_OVERWRITE=$((L_OVERWRITE + 1))
			;;
		backup)
			backup="$dst.backup.$(date +%Y%m%d-%H%M%S)"
			if $DRY_RUN; then
				say "would back up $dst to $backup"
			else
				mv "$dst" "$backup"
				say "backed up $dst to $backup"
			fi
			L_BACKUP=$((L_BACKUP + 1))
			;;
		*)
			say "skipped $dst"
			L_SKIP=$((L_SKIP + 1))
			return
			;;
		esac
	fi

	if $DRY_RUN; then
		say "would link $dst -> $src"
		L_LINKED=$((L_LINKED + 1))
		return
	fi
	mkdir -p "$(dirname "$dst")"
	if ln -s "$src" "$dst"; then
		say "linked $dst -> $src"
		L_LINKED=$((L_LINKED + 1))
	else
		bad "could not link $dst"
	fi
}

step_links() {
	local linkfile line src dst
	L_OK=0 L_LINKED=0 L_BACKUP=0 L_OVERWRITE=0 L_SKIP=0 L_ASK=0

	while IFS= read -r linkfile; do
		say "${DIM}${linkfile#"$DOTFILES"/}${RESET}"
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

	if $DRY_RUN; then
		SUMMARY=$(join_parts \
			"$L_OK up to date" \
			"$([[ $L_LINKED -gt 0 ]] && echo "would link $L_LINKED")" \
			"$([[ $L_BACKUP -gt 0 ]] && echo "would back up $L_BACKUP")" \
			"$([[ $L_OVERWRITE -gt 0 ]] && echo "would overwrite $L_OVERWRITE")" \
			"$([[ $L_SKIP -gt 0 ]] && echo "$L_SKIP skipped")" \
			"$([[ $L_ASK -gt 0 ]] && echo "$L_ASK conflict(s) to decide")")
	else
		SUMMARY=$(join_parts \
			"$L_OK up to date" \
			"$([[ $L_LINKED -gt 0 ]] && echo "$L_LINKED linked")" \
			"$([[ $L_BACKUP -gt 0 ]] && echo "$L_BACKUP backed up")" \
			"$([[ $L_OVERWRITE -gt 0 ]] && echo "$L_OVERWRITE overwritten")" \
			"$([[ $L_SKIP -gt 0 ]] && echo "$L_SKIP skipped")")
	fi
}

# ---------------------------------------------------------------------------
# Step: plugins (sheldon, tmux)
# ---------------------------------------------------------------------------
step_plugins() {
	command -v brew &>/dev/null || brew_shellenv || true

	local tpm_dir="$HOME/.tmux/plugins/tpm" n_sheldon n_tmux parts=()
	n_sheldon=$(grep -c '^\[plugins\.' "$DOTFILES/sheldon/plugins.toml")
	n_tmux=$(grep -c '^set -g @plugin' "$DOTFILES/tmux/.tmux.conf")

	# sheldon
	if ! command -v sheldon &>/dev/null; then
		if $DRY_RUN; then
			parts+=("sheldon not installed yet (needs packages)")
		else
			bad "sheldon is not installed (run: ./install.sh packages)"
		fi
	elif $DRY_RUN; then
		say "would run: sheldon lock"
		parts+=("would sync $n_sheldon sheldon")
	elif run sheldon lock; then
		parts+=("$n_sheldon sheldon")
	else
		bad "sheldon lock failed"
	fi

	# tmux plugin manager + plugins
	if ! command -v tmux &>/dev/null; then
		if $DRY_RUN; then
			parts+=("tmux not installed yet (needs packages)")
		else
			bad "tmux is not installed (run: ./install.sh packages)"
		fi
	elif $DRY_RUN; then
		if [[ -d "$tpm_dir" ]]; then
			say "TPM is installed; would run: tpm install_plugins"
		else
			say "would clone TPM, then run: tpm install_plugins"
		fi
		parts+=("would sync $n_tmux tmux")
	else
		if [[ ! -d "$tpm_dir" ]]; then
			if run git clone --quiet https://github.com/tmux-plugins/tpm "$tpm_dir"; then
				say "cloned TPM"
			else
				bad "could not clone TPM"
			fi
		fi
		if [[ -d "$tpm_dir" ]]; then
			tmux new-session -d -s tpm_install 2>/dev/null || true
			if run "$tpm_dir/bin/install_plugins"; then
				parts+=("$n_tmux tmux")
			else
				bad "tmux plugin install failed"
			fi
			tmux kill-session -t tpm_install 2>/dev/null || true
		fi
	fi

	SUMMARY=$(join_parts "${parts[@]+"${parts[@]}"}")
	[[ -n "$SUMMARY" ]] && ! $DRY_RUN && [[ $N_FAILED -eq 0 ]] && SUMMARY="$SUMMARY plugins"
	[[ -n "$SUMMARY" ]] || SUMMARY="nothing to do"
}

# ---------------------------------------------------------------------------
# Runner and main
# ---------------------------------------------------------------------------
# run_step <index> <total> <name>
run_step() {
	local idx=$1 total=$2 name=$3 start=$SECONDS elapsed mark color
	STEP_NAME=$name
	STEP_LOG="$LOG_DIR/$name.log"
	: >"$STEP_LOG"
	SUMMARY=
	N_FAILED=0
	LAST_FAIL=

	if $VERBOSE; then
		printf '%s==> [%d/%d] %s%s\n' "$DIM" "$idx" "$total" "$name" "$RESET"
	elif $TTY; then
		printf '[%d/%d] %-9s %s...%s' "$idx" "$total" "$name" "$DIM" "$RESET"
	fi

	"step_$name"

	elapsed=$((SECONDS - start))
	if [[ $N_FAILED -gt 0 ]]; then
		mark='✗' color=$RED
		if [[ $N_FAILED -eq 1 ]]; then SUMMARY=$LAST_FAIL; else SUMMARY="$N_FAILED failures, see below"; fi
	elif $DRY_RUN; then
		mark='~' color=$YELLOW
	else
		mark='✓' color=$GREEN
	fi
	$TTY && ! $VERBOSE && printf '\r\033[2K'
	printf '[%d/%d] %-9s %s%s%s %-58s %s%s%s\n' "$idx" "$total" "$name" "$color" "$mark" "$RESET" "$SUMMARY" "$DIM" "$([[ $elapsed -ge 1 ]] && echo "${elapsed}s" || echo '<1s')" "$RESET"

	# quiet mode: show the tail of the log for a failed step
	if [[ $N_FAILED -gt 0 ]] && ! $VERBOSE; then
		tail -n 20 "$STEP_LOG" | sed 's/^/        /'
		printf '        full log: %s\n' "$STEP_LOG"
	fi
}

usage() {
	sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
}

cleanup() {
	[[ -n "$LOG_DIR" && ${#FAILURES[@]} -eq 0 ]] && rm -rf "$LOG_DIR"
	return 0
}

main() {
	local steps=() step i=0 total start=$SECONDS

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help | help)
			usage
			exit 0
			;;
		-v | --verbose) VERBOSE=true ;;
		-n | --dry-run) DRY_RUN=true ;;
		packages | links | plugins) steps+=("$1") ;;
		*)
			echo "unknown argument: $1 (see ./install.sh --help)" >&2
			exit 2
			;;
		esac
		shift
	done
	[[ ${#steps[@]} -gt 0 ]] || steps=(packages links plugins)
	total=${#steps[@]}

	LOG_DIR=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-install.XXXXXX")
	trap cleanup EXIT

	printf '%sdotfiles · %s · %s%s%s\n' "$DIM" "$OS" "$DOTFILES" "$($DRY_RUN && echo ' · DRY RUN, nothing will be changed')" "$RESET"
	echo

	for step in "${steps[@]}"; do
		i=$((i + 1))
		run_step "$i" "$total" "$step"
	done
	echo

	if [[ ${#FAILURES[@]} -gt 0 ]]; then
		printf '%s%d problem(s):%s\n' "$RED" "${#FAILURES[@]}" "$RESET"
		printf '  - %s\n' "${FAILURES[@]}"
		printf 'Logs kept in %s\n' "$LOG_DIR"
		exit 1
	fi

	if $DRY_RUN; then
		echo "Dry run finished in $((SECONDS - start))s. Nothing was changed."
	else
		echo "Done in $((SECONDS - start))s. Open a new terminal, or run: source ~/.zshrc"
		[[ " ${steps[*]} " == *" plugins "* ]] && echo "For neovim, run 'nvim' once to let LazyVim install its plugins."
	fi
	return 0
}

main "$@"
