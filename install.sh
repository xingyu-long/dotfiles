#!/bin/bash
#
# install.sh - Main installation script for dotfiles
# This script installs Homebrew (if needed), installs packages, and creates
# symbolic links based on links.prop files in each component folder.
# Packages are read from deps/deps-macos.txt file.

set -e

# Get the directory where this script is located
cd "$(dirname "$0")"
DOTFILES=$(pwd -P)

# Color output functions
info() {
	printf "\r  [ \033[00;34m..\033[0m ] %s\n" "$1"
}

user() {
	printf "\r  [ \033[0;33m??\033[0m ] %s\n" "$1"
}

success() {
	printf "\r\033[2K  [ \033[00;32mOK\033[0m ] %s\n" "$1"
}

fail() {
	printf "\r\033[2K  [\033[0;31mFAIL\033[0m] %s\n" "$1"
	echo ''
	exit 1
}

# Eval Homebrew shellenv from the first known install path found
_brew_shellenv() {
	local brew_path
	for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
		if [[ -x "$brew_path" ]]; then
			eval "$("$brew_path" shellenv)"
			return 0
		fi
	done
}

# Function to install packages using Homebrew
install_packages() {
	info "Checking and installing packages..."

	if ! command -v brew &>/dev/null; then
		info "Homebrew not found. Installing Homebrew..."
		NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		_brew_shellenv
		success "Homebrew installed successfully"
	else
		success "Homebrew is already installed"
	fi

	# Read packages from deps-macos.txt file
	local deps_file="$DOTFILES/deps/deps-macos.txt"
	if [ ! -f "$deps_file" ]; then
		fail "Dependencies file not found: $deps_file"
	fi

	# Read packages from file, filtering out comments and empty lines
	packages=()
	while IFS= read -r line; do
		# Skip empty lines and comments
		if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
			packages+=("$line")
		fi
	done <"$deps_file"

	# Install packages
	local installed_count=0
	local skipped_count=0

	for package in "${packages[@]}"; do
		if ! brew list "$package" &>/dev/null; then
			info "Installing $package..."
			if brew install "$package"; then
				success "$package installed"
				installed_count=$((installed_count + 1))
			else
				fail "Failed to install $package"
			fi
		else
			success "$package is already installed"
			skipped_count=$((skipped_count + 1))
		fi
	done

	info "Package installation summary: $installed_count installed, $skipped_count already present"
}

# Global variables for link handling (can be overridden by env vars)
OVERWRITE_ALL=${DOTFILES_OVERWRITE_ALL:-false}
BACKUP_ALL=${DOTFILES_BACKUP_ALL:-false}
SKIP_ALL=${DOTFILES_SKIP_ALL:-false}

# Function to create symbolic links based on links.prop files
link_file() {
	local src=$1 dst=$2

	local overwrite=
	local backup=
	local skip=
	local action=

	if [ -f "$dst" ] || [ -d "$dst" ] || [ -L "$dst" ]; then
		# Check if the existing link points to the same source
		local currentSrc
		currentSrc="$(readlink "$dst" 2>/dev/null || echo "")"

		if [ "$currentSrc" == "$src" ]; then
			success "symlink already exists and points to correct location: $dst"
			return 0
		fi

		if [ "$OVERWRITE_ALL" == "false" ] && [ "$BACKUP_ALL" == "false" ] && [ "$SKIP_ALL" == "false" ]; then
			# Check if we are in a non-interactive shell (no TTY)
			if [ ! -t 0 ] || [ ! -e /dev/tty ]; then
				info "Non-interactive environment detected, skipping conflict for $dst"
				skip=true
			else
				user "File already exists: $dst ($(basename "$src")), what do you want to do?
      [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all?"
				read -r -n 1 action </dev/tty

				case "$action" in
				o)
					overwrite=true
					;;
				O)
					OVERWRITE_ALL=true
					;;
				b)
					backup=true
					;;
				B)
					BACKUP_ALL=true
					;;
				s)
					skip=true
					;;
				S)
					SKIP_ALL=true
					;;
				*) ;;
				esac
			fi
		fi

		overwrite=${overwrite:-$OVERWRITE_ALL}
		backup=${backup:-$BACKUP_ALL}
		skip=${skip:-$SKIP_ALL}

		if [ "$overwrite" == "true" ]; then
			rm -rf "$dst"
			success "removed $dst"
		fi

		if [ "$backup" == "true" ]; then
			mv "$dst" "${dst}.backup"
			success "moved $dst to ${dst}.backup"
		fi

		if [ "$skip" == "true" ]; then
			success "skipped $src"
			return 0
		fi
	fi

	if [ "$skip" != "true" ]; then
		ln -s "$src" "$dst"
		success "linked $src to $dst"
	fi
}

# Function to install dotfiles by creating symbolic links
install_dotfiles() {
	info "Installing dotfiles by creating symbolic links..."

	# Find all links.prop files and process them
	# Use process substitution instead of pipe to avoid subshell issues with global variables
	while read -r linkfile; do
		info "Processing $linkfile"

		while read -r line; do
			# Skip empty lines and comments
			if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
				continue
			fi

			local src dst dir
			src=$(eval echo "$line" | cut -d '=' -f 1)
			dst=$(eval echo "$line" | cut -d '=' -f 2)
			dir=$(dirname "$dst")

			# Create destination directory if it doesn't exist
			mkdir -p "$dir"
			link_file "$src" "$dst"
		done <"$linkfile"
	done < <(find "$DOTFILES" -maxdepth 2 -name 'links.prop' -not -path '*.git*')
}

# Function to link Homebrew-installed zsh plugins into Oh My Zsh custom plugins dir
setup_zsh_plugins() {
	local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
	local brew_prefix
	brew_prefix="$(brew --prefix)"

	for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
		local plugin_src="$brew_prefix/share/$plugin"
		local plugin_dst="$zsh_custom/plugins/$plugin"

		if [ ! -d "$plugin_src" ]; then
			info "$plugin not found at $plugin_src, skipping"
			continue
		fi

		if [ -L "$plugin_dst" ] && [ "$(readlink "$plugin_dst")" = "$plugin_src" ]; then
			success "$plugin already linked"
		elif [ -L "$plugin_dst" ] || [ -d "$plugin_dst" ]; then
			rm -rf "$plugin_dst"
			ln -s "$plugin_src" "$plugin_dst"
			success "replaced $plugin with correct symlink"
		else
			mkdir -p "$zsh_custom/plugins"
			ln -s "$plugin_src" "$plugin_dst"
			success "linked $plugin to Oh My Zsh custom plugins"
		fi
	done
}

# Function to install Oh My Zsh
setup_ohmyzsh() {
	local omz_dir="$HOME/.oh-my-zsh"

	if [ ! -d "$omz_dir" ]; then
		info "Installing Oh My Zsh..."
		if RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; then
			success "Oh My Zsh installed"
		else
			fail "Failed to install Oh My Zsh"
		fi
	else
		success "Oh My Zsh is already installed"
	fi
}

# Function to install TPM and tmux plugins
setup_tmux() {
	local tpm_dir="$HOME/.tmux/plugins/tpm"

	if [ ! -d "$tpm_dir" ]; then
		info "Installing TPM (Tmux Plugin Manager)..."
		if git clone https://github.com/tmux-plugins/tpm "$tpm_dir"; then
			success "TPM installed"
		else
			fail "Failed to clone TPM"
		fi
	else
		success "TPM is already installed"
	fi

	info "Installing tmux plugins..."
	tmux new-session -d -s tpm_install 2>/dev/null || true
	if "$tpm_dir/bin/install_plugins"; then
		success "tmux plugins installed"
	else
		fail "Failed to install tmux plugins"
	fi
	tmux kill-session -t tpm_install 2>/dev/null || true
}

# Function to create environment file
create_env_file() {
	if test -f "$HOME/.env.sh"; then
		success "$HOME/.env.sh file already exists, skipping"
	else
		echo "export DOTFILES=$DOTFILES" >"$HOME/.env.sh"
		success "created ~/.env.sh"
	fi
}

# Function to copy additional files that don't use symbolic links
copy_additional_files() {
	info "Checking and copying additional configuration files..."

	# Copy lazygit config
	if [ -f "$DOTFILES/lazygit/config.yml" ]; then
		local lazygit_dir="$HOME/.config/lazygit"
		local lazygit_dst="$lazygit_dir/config.yml"
		mkdir -p "$lazygit_dir"

		if [ -f "$lazygit_dst" ]; then
			if ! cmp -s "$DOTFILES/lazygit/config.yml" "$lazygit_dst"; then
				cp "$DOTFILES/lazygit/config.yml" "$lazygit_dst"
				success "updated lazygit config"
			else
				success "lazygit config is already up to date"
			fi
		else
			cp "$DOTFILES/lazygit/config.yml" "$lazygit_dst"
			success "copied lazygit config"
		fi
	fi

	# Copy vscode settings
	if [ -f "$DOTFILES/vscode/settings.json" ]; then
		# Different paths for macOS vs Linux
		if [[ "$OSTYPE" == "darwin"* ]]; then
			local vscode_dir="$HOME/Library/Application Support/Code/User"
		else
			local vscode_dir="$HOME/.config/Code/User"
		fi
		local vscode_dst="$vscode_dir/settings.json"
		mkdir -p "$vscode_dir"

		if [ -f "$vscode_dst" ]; then
			if ! cmp -s "$DOTFILES/vscode/settings.json" "$vscode_dst"; then
				cp "$DOTFILES/vscode/settings.json" "$vscode_dst"
				success "updated vscode settings"
			else
				success "vscode settings are already up to date"
			fi
		else
			cp "$DOTFILES/vscode/settings.json" "$vscode_dst"
			success "copied vscode settings"
		fi
	fi

}

# Main execution
main() {
	echo ""
	info "Starting dotfiles installation..."
	info "This script is idempotent - safe to run multiple times"
	echo ""

	# Track what was done
	local packages_installed=false
	local symlinks_created=false
	local files_copied=false
	local ohmyzsh_setup=false
	local zsh_plugins_setup=false
	local tmux_setup=false
	local env_created=false

	# Install packages
	install_packages
	packages_installed=true
	echo ""

	# Install Oh My Zsh before symlinking .zshrc so the config is valid on first load
	setup_ohmyzsh
	ohmyzsh_setup=true
	echo ""

	# Link Homebrew zsh plugins into Oh My Zsh custom plugins dir
	setup_zsh_plugins
	zsh_plugins_setup=true
	echo ""

	# Install dotfiles (create symbolic links)
	install_dotfiles
	symlinks_created=true
	echo ""

	# Copy additional files
	copy_additional_files
	files_copied=true
	echo ""

	# Set up tmux (TPM + plugins)
	setup_tmux
	tmux_setup=true
	echo ""

	# Create environment file
	create_env_file
	env_created=true
	echo ""

	success "Installation completed successfully!"
	echo ""
	info "Summary of actions:"
	echo "  ✓ Package installation: $([ "$packages_installed" = true ] && echo "completed" || echo "skipped")"
	echo "  ✓ Symbolic links: $([ "$symlinks_created" = true ] && echo "created/verified" || echo "skipped")"
	echo "  ✓ Configuration files: $([ "$files_copied" = true ] && echo "copied/updated" || echo "skipped")"
	echo "  ✓ Oh My Zsh: $([ "$ohmyzsh_setup" = true ] && echo "completed" || echo "skipped")"
	echo "  ✓ Zsh plugins: $([ "$zsh_plugins_setup" = true ] && echo "completed" || echo "skipped")"
	echo "  ✓ Tmux setup: $([ "$tmux_setup" = true ] && echo "completed" || echo "skipped")"
	echo "  ✓ Environment setup: $([ "$env_created" = true ] && echo "completed" || echo "skipped")"
	echo ""
	info "Next steps:"
	echo "  - Restart your terminal or run 'source ~/.zshrc'"
	echo "  - For tmux: plugins were installed automatically; reload with Ctrl+A, r"
	echo "  - For neovim: run 'nvim' to initialize LazyVim"
	echo ""
	info "You can run this script again anytime to update configurations!"
	echo ""
}

# Run main function
main "$@"
