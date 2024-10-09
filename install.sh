#!/bin/bash

install_neovim_centos() {
  # Add EPEL repository for Neovim
  sudo yum install -y epel-release
  # Install Neovim
  sudo yum install -y neovim
}

if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "macOS detected"

  # Check if Homebrew is installed
  if ! command -v brew &>/dev/null; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    echo "Homebrew is already installed"
  fi

  # Check and install Neovim, ripgrep, and Node.js if not already installed
  packages=("neovim" "ripgrep" "node")
  for package in "${packages[@]}"; do
    if ! brew list $package &>/dev/null; then
      echo "Installing $package..."
      brew install $package
    else
      echo "$package is already installed"
    fi
  done

elif [[ -f /etc/centos-release ]]; then
  echo "CentOS detected"

  # Check and install Neovim, ripgrep, and Node.js if not already installed
  if ! command -v nvim &>/dev/null; then
    echo "Installing Neovim..."
    install_neovim_centos
  else
    echo "Neovim is already installed"
  fi

  if ! command -v rg &>/dev/null; then
    echo "Installing ripgrep..."
    sudo yum install -y ripgrep
  else
    echo "ripgrep is already installed"
  fi

  if ! command -v node &>/dev/null; then
    echo "Installing Node.js..."
    curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
    sudo yum install -y nodejs
  else
    echo "Node.js is already installed"
  fi

else
  echo "This script supports macOS and CentOS only"
  exit 1
fi

backup_and_install_lazyvim() {
  echo "Setting up Neovim..."
  # Backup existing Neovim config and related directories
  dirs_to_backup=(
    "$HOME/.config/nvim"
    "$HOME/.local/share/nvim"
    "$HOME/.local/state/nvim"
    "$HOME/.cache/nvim"
  )

  for dir in "${dirs_to_backup[@]}"; do
    if [ -d "$dir" ]; then
        backup_dir="${dir}.bak"

        # Remove the existing backup directory if it exists
        if [ -d "$backup_dir" ]; then
            echo "Removing existing backup directory $backup_dir"
            rm -rf "$backup_dir"
        fi

        echo "Backing up $dir to $backup_dir"
        mv "$dir" "$backup_dir"
    fi
  done

  # Create new Neovim config directory and copy LazyVim config
  nvim_config_dir="$HOME/.config/nvim"
  echo "Copying LazyVim config to $nvim_config_dir"
  mkdir -p "$nvim_config_dir"
  cp -R ./lazyvim/* "$nvim_config_dir/"
  cp ./vscode/vscode_init.vim "$nvim_config_dir/"
  echo "LazyVim config copied successfully"
  echo "Neovim setup complete."
}

setup_tmux_conf() {
  echo "Setting up Tmux configuration..."
  cp ./.tmux.conf ~/.tmux.conf
  echo "Tmux configuration file copied to home directory"

  # Install tmux plugins manager
  if [ ! -d ~/.tmux/plugins/tpm ]; then
    echo "Installing Tmux Plugin Manager..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  else
    echo "Tmux Plugin Manager is already installed"
  fi

  # Source the tmux configuration
  if command -v tmux &>/dev/null; then
    echo "Sourcing Tmux configuration..."
    tmux source ~/.tmux.conf
  else
    echo "Tmux is not installed. Please install Tmux to use the configuration."
  fi

  echo "Tmux setup complete."
  echo "Remember to install all plugins through TPM by pressing Ctrl+A, Shift+I in a Tmux session."
}

# Main script execution
backup_and_install_lazyvim
setup_tmux_conf
echo "Enjoy your new development environment!"

# TODO:
# 1. ".zshrc" template with pre-installed plugins
# 2. lazygit
# 3. use homebrew for linux as well
