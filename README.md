# Dotfiles

A comprehensive collection of development environment configurations for macOS, featuring modern tools and optimized workflows.

## 🚀 Quick Start

```shell
./install.sh
```

That's it! The installation script will handle everything automatically.

## 📋 What's Included

This dotfiles repository provides configurations for:

- **Neovim** - Modern Vim with LazyVim configuration
- **Alacritty** - GPU-accelerated terminal emulator
- **WezTerm** - Cross-platform terminal emulator
- **Starship** - Fast, customizable shell prompt
- **Tmux** - Terminal multiplexer with plugins
- **LazyGit** - Simple terminal UI for Git
- **VS Code** - Editor settings and configuration

## 🛠 Installation Process

The `install.sh` script is **idempotent** - safe to run multiple times. It will:

### 1. Package Installation
- Installs Homebrew (if not present)
- Installs all required packages from `deps/deps-macos.txt`:
  - **Editor**: neovim
  - **General tools**: fzf, node, ripgrep, tree, wget, tmux, gnupg
  - **Python tools**: uv
  - **Git tool**: lazygit
  - **Zsh plugins**: zsh-autosuggestions, zsh-syntax-highlighting

### 2. Symbolic Link Creation
- Creates symbolic links based on `links.prop` files in each component folder
- Handles existing files gracefully with interactive prompts
- Automatically skips if links already point to correct locations

### 3. Configuration File Copying
- Copies additional configuration files that don't use symbolic links
- Only updates files when content has changed
- Maintains existing configurations when possible

### 4. Environment Setup
- Creates `~/.env.sh` with DOTFILES path
- Sets up necessary environment variables

## 📁 Repository Structure

```
dotfiles/
├── install.sh              # Main installation script
├── deps/
│   └── deps-macos.txt      # Package dependencies list
├── alacritty/              # Terminal emulator config
│   ├── alacritty.toml
│   ├── dracula.toml
│   └── links.prop
├── lazyvim/                # Neovim configuration
│   ├── init.lua
│   ├── lazyvim.json
│   ├── links.prop
│   └── lua/
├── starship/               # Shell prompt
│   ├── starship.toml
│   └── links.prop
├── tmux/                   # Terminal multiplexer
│   └── links.prop
├── lazygit/                # Git UI
│   └── config.yml
├── vscode/                 # VS Code settings
│   ├── settings.json
│   └── vscode_init.vim
└── wezterm/                # Terminal emulator
    ├── wezterm.lua
    └── colors/
```

## 🔧 Configuration Files

### Symbolic Links (via `links.prop`)
Each component folder contains a `links.prop` file that defines symbolic link mappings:

- `alacritty/alacritty.toml` → `~/.config/alacritty/alacritty.toml`
- `lazyvim/` → `~/.config/nvim`
- `starship/starship.toml` → `~/.config/starship/starship.toml`
- `tmux/.tmux.conf` → `~/.tmux.conf`

### Direct Copy Files
Some configurations are copied directly (not symlinked):

- `lazygit/config.yml` → `~/.config/lazygit/config.yml`
- `vscode/settings.json` → `~/Library/Application Support/Code/User/settings.json`
- `wezterm/wezterm.lua` → `~/.config/wezterm/wezterm.lua`
- `wezterm/colors/` → `~/.config/wezterm/colors/`

## 🎯 Features

- **Idempotent Installation**: Run the script multiple times safely
- **Smart Updates**: Only updates files when content changes
- **Interactive Conflict Resolution**: Handles existing files gracefully
- **Comprehensive Package Management**: Installs all dependencies automatically
- **Cross-Component Integration**: All tools work together seamlessly

## 🔄 Updating

To update your dotfiles:

1. Pull the latest changes:
   ```shell
   git pull origin main
   ```

2. Run the installation script again:
   ```shell
   ./install.sh
   ```

The script will only update what's changed, making updates fast and safe.

## 🐛 Troubleshooting

### Common Issues

**Q: nvim-treesitter error when using nvim?**
- A: Run `:TSInstall lua` to reinstall the parser.

**Q: Tmux plugins not working?**
- A: Install plugins by pressing `Ctrl+A, Shift+I` in a tmux session.

**Q: Shell prompt not showing correctly?**
- A: Restart your terminal or run `source ~/.zshrc`.

**Q: Homebrew not found after installation?**
- A: Restart your terminal or run `eval "$(/opt/homebrew/bin/brew shellenv)"`.

### Manual Steps After Installation

1. **Restart your terminal** or run `source ~/.zshrc`
2. **Initialize Neovim**: Run `nvim` to set up LazyVim
3. **Install Tmux plugins**: Press `Ctrl+A, Shift+I` in tmux
4. **Configure Git**: Set up your Git user name and email

## 🎨 Customization

### Adding New Packages
Edit `deps/deps-macos.txt` to add or remove packages:

```txt
# Add your package here
your-package-name
```

### Adding New Components
1. Create a new folder with your configuration files
2. Add a `links.prop` file if using symbolic links
3. Update `install.sh` if you need custom copying logic

### Modifying Existing Configurations
- Edit files directly in their respective folders
- Run `./install.sh` to apply changes
- The script will detect changes and update accordingly

## 📝 Requirements

- **macOS** (currently supported platform)
- **Internet connection** (for package downloads)
- **Git** (for cloning the repository)