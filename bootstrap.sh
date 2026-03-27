#!/bin/bash
#
# bootstrap.sh - One-liner install entry point
# Usage: curl -fsSL https://raw.githubusercontent.com/xingyu-long/dotfiles/main/bootstrap.sh | bash

set -e

DOTFILES_REPO="https://github.com/xingyu-long/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

# Color output
info() { printf "\r  [ \033[00;34m..\033[0m ] %s\n" "$1"; }
success() { printf "\r\033[2K  [ \033[00;32mOK\033[0m ] %s\n" "$1"; }
fail() {
	printf "\r\033[2K  [\033[0;31mFAIL\033[0m] %s\n" "$1"
	exit 1
}

# Ensure git is available
if ! command -v git &>/dev/null; then
	fail "git is required but not installed"
fi

# Clone or update the dotfiles repo
if [ -d "$DOTFILES_DIR/.git" ]; then
	info "Dotfiles already cloned, pulling latest..."
	git -C "$DOTFILES_DIR" pull --rebase
	success "Dotfiles updated"
else
	info "Cloning dotfiles into $DOTFILES_DIR..."
	git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
	success "Dotfiles cloned"
fi

# Hand off to the main install script
bash "$DOTFILES_DIR/install.sh"
