#!/bin/bash
#
# install.sh - Main installation script for dotfiles
# This script installs necessary packages for macOS and creates symbolic links
# based on links.prop files in each component folder.
# Packages are read from deps/deps-macos.txt file.

set -e

# Get the directory where this script is located
cd "$(dirname "$0")"
DOTFILES=$(pwd -P)

# Color output functions
info () {
  printf "\r  [ \033[00;34m..\033[0m ] $1\n"
}

user () {
  printf "\r  [ \033[0;33m??\033[0m ] $1\n"
}

success () {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

fail () {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
  echo ''
  exit 1
}

# Function to install packages using Homebrew
install_macos_packages() {
  info "Checking and installing packages..."
  
  # Check if Homebrew is installed
  if ! command -v brew &>/dev/null; then
    info "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs (macOS only)
    if [[ "$OSTYPE" == "darwin"* ]] && [[ $(uname -m) == "arm64" ]]; then
      # Check if the line already exists in .zprofile to avoid duplicates
      if ! grep -q 'eval "$(/opt/homebrew/bin/brew shellenv)"' ~/.zprofile 2>/dev/null; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        success "Added Homebrew to PATH in ~/.zprofile"
      fi
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
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
  done < "$deps_file"

  # Install packages
  local installed_count=0
  local skipped_count=0
  
  for package in "${packages[@]}"; do
    if ! brew list "$package" &>/dev/null; then
      info "Installing $package..."
      if brew install "$package"; then
        success "$package installed"
        ((installed_count++))
      else
        fail "Failed to install $package"
      fi
    else
      success "$package is already installed"
      ((skipped_count++))
    fi
  done
  
  info "Package installation summary: $installed_count installed, $skipped_count already present"
}

# Function to create symbolic links based on links.prop files
link_file() {
  local src=$1 dst=$2

  local overwrite=
  local backup=
  local skip=
  local action=

  if [ -f "$dst" ] || [ -d "$dst" ] || [ -L "$dst" ]; then
    # Check if the existing link points to the same source
    local currentSrc="$(readlink "$dst" 2>/dev/null || echo "")"

    if [ "$currentSrc" == "$src" ]; then
      success "symlink already exists and points to correct location: $dst"
      return 0
    fi

    if [ "$overwrite_all" == "false" ] && [ "$backup_all" == "false" ] && [ "$skip_all" == "false" ]; then
      user "File already exists: $dst ($(basename "$src")), what do you want to do?
      [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all?"
      read -n 1 action < /dev/tty

      case "$action" in
        o )
          overwrite=true;;
        O )
          overwrite_all=true;;
        b )
          backup=true;;
        B )
          backup_all=true;;
        s )
          skip=true;;
        S )
          skip_all=true;;
        * )
          ;;
      esac
    fi

    overwrite=${overwrite:-$overwrite_all}
    backup=${backup:-$backup_all}
    skip=${skip:-$skip_all}

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

  local overwrite_all=false backup_all=false skip_all=false

  # Find all links.prop files and process them
  find "$DOTFILES" -maxdepth 2 -name 'links.prop' -not -path '*.git*' | while read linkfile; do
    info "Processing $linkfile"
    
    cat "$linkfile" | while read line; do
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
    done
  done
}

# Function to create environment file
create_env_file() {
  if test -f "$HOME/.env.sh"; then
    success "$HOME/.env.sh file already exists, skipping"
  else
    echo "export DOTFILES=$DOTFILES" > "$HOME/.env.sh"
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
  
  # Copy wezterm config
  if [ -f "$DOTFILES/wezterm/wezterm.lua" ]; then
    local wezterm_dir="$HOME/.config/wezterm"
    local wezterm_dst="$wezterm_dir/wezterm.lua"
    mkdir -p "$wezterm_dir"
    
    if [ -f "$wezterm_dst" ]; then
      if ! cmp -s "$DOTFILES/wezterm/wezterm.lua" "$wezterm_dst"; then
        cp "$DOTFILES/wezterm/wezterm.lua" "$wezterm_dst"
        success "updated wezterm config"
      else
        success "wezterm config is already up to date"
      fi
    else
      cp "$DOTFILES/wezterm/wezterm.lua" "$wezterm_dst"
      success "copied wezterm config"
    fi
  fi
  
  # Copy wezterm colors
  if [ -d "$DOTFILES/wezterm/colors" ]; then
    local wezterm_dir="$HOME/.config/wezterm"
    local wezterm_colors_dst="$wezterm_dir/colors"
    mkdir -p "$wezterm_dir"
    
    if [ -d "$wezterm_colors_dst" ]; then
      if ! diff -r "$DOTFILES/wezterm/colors" "$wezterm_colors_dst" >/dev/null 2>&1; then
        rm -rf "$wezterm_colors_dst"
        cp -r "$DOTFILES/wezterm/colors" "$wezterm_dir/"
        success "updated wezterm colors"
      else
        success "wezterm colors are already up to date"
      fi
    else
      cp -r "$DOTFILES/wezterm/colors" "$wezterm_dir/"
      success "copied wezterm colors"
    fi
  fi
}

# Main execution
main() {
  echo ""
  info "Starting dotfiles installation..."
  info "This script is idempotent - safe to run multiple times"
  echo ""

  # Check if running on macOS or if Homebrew is available on non-Mac
  if [[ "$OSTYPE" != "darwin"* ]]; then
    if ! command -v brew &>/dev/null; then
      fail "This script currently only supports macOS. On non-Mac systems, Homebrew must be preinstalled."
    fi
    info "Detected non-macOS system with Homebrew installed, continuing..."
  fi

  # Track what was done
  local packages_installed=false
  local symlinks_created=false
  local files_copied=false
  local env_created=false

  # Install packages
  install_macos_packages
  packages_installed=true
  echo ""

  # Install dotfiles (create symbolic links)
  install_dotfiles
  symlinks_created=true
  echo ""

  # Copy additional files
  copy_additional_files
  files_copied=true
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
  echo "  ✓ Environment setup: $([ "$env_created" = true ] && echo "completed" || echo "skipped")"
  echo ""
  info "Next steps:"
  echo "  - Restart your terminal or run 'source ~/.zshrc'"
  echo "  - For tmux: install plugins with Ctrl+A, Shift+I"
  echo "  - For neovim: run 'nvim' to initialize LazyVim"
  echo ""
  info "You can run this script again anytime to update configurations!"
  echo ""
}

# Run main function
main "$@"
