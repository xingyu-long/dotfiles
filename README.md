# Dotfiles

A comprehensive collection of development environment configurations for macOS and Linux, featuring modern tools and optimized workflows.

![CI](https://github.com/xingyu-long/dotfiles/actions/workflows/test.yml/badge.svg)

## Quick Start

**Fresh machine — one-liner install:**

```bash
curl -fsSL https://raw.githubusercontent.com/xingyu-long/dotfiles/main/bootstrap.sh | bash
```

**Already cloned the repo:**

```bash
./install.sh
```

The installation script is **idempotent** — safe to run multiple times.

## What's Included

| Tool | Description |
|---|---|
| **Zsh + Oh My Zsh** | Shell with plugins and `ys` theme |
| **Neovim** | Modern Vim with LazyVim configuration |
| **Tmux** | Terminal multiplexer with TPM plugins |
| **Starship** | Fast, customizable shell prompt |
| **LazyGit** | Terminal UI for Git |
| **Alacritty** | GPU-accelerated terminal emulator |
| **WezTerm** | Cross-platform terminal emulator |
| **VS Code** | Editor settings and configuration |

## Installation Process

The `install.sh` script performs the following steps in order:

1. **Homebrew** — installs if not present (works on macOS and Linux)
2. **Packages** — installs everything in `deps/deps-macos.txt` via `brew`
3. **Symlinks** — creates symbolic links from `links.prop` files in each component folder
4. **Config files** — copies files that don't use symlinks (lazygit, vscode)
5. **Oh My Zsh** — installs if not present
6. **Tmux** — installs TPM and plugins
7. **Environment** — creates `~/.env.sh` with the `$DOTFILES` path

## Repository Structure

```
dotfiles/
├── bootstrap.sh            # One-liner entry point (clones repo + runs install.sh)
├── install.sh              # Main installation script
├── Dockerfile.test         # Docker image for local testing
├── deps/
│   └── deps-macos.txt      # Homebrew package list
├── zsh/
│   ├── .zshrc
│   └── links.prop
├── alacritty/
│   ├── alacritty.toml
│   ├── dracula.toml
│   └── links.prop
├── lazyvim/                # Neovim configuration
│   ├── init.lua
│   ├── lazyvim.json
│   ├── links.prop
│   └── lua/
├── starship/
│   ├── starship.toml
│   └── links.prop
├── tmux/
│   └── links.prop
├── lazygit/
│   └── config.yml
├── vscode/
│   ├── settings.json
│   └── vscode_init.vim
└── wezterm/
    ├── wezterm.lua
    └── colors/
```

## Symlinks (via `links.prop`)

Each component folder contains a `links.prop` file defining mappings in the form `$DOTFILES/path=$HOME/path`:

| Source | Destination |
|---|---|
| `zsh/.zshrc` | `~/.zshrc` |
| `alacritty/alacritty.toml` | `~/.config/alacritty/alacritty.toml` |
| `lazyvim/` | `~/.config/nvim` |
| `starship/starship.toml` | `~/.config/starship/starship.toml` |
| `tmux/.tmux.conf` | `~/.tmux.conf` |

## Testing

### Local (Docker)

```bash
# Full install smoke test
docker build -f Dockerfile.test -t dotfiles-test .

# Verify installation
docker run --rm dotfiles-test zsh -c "
  eval \"\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\" &&
  brew --version && echo 'brew: OK' &&
  [ -d \$HOME/.oh-my-zsh ] && echo 'oh-my-zsh: OK' &&
  [ -L \$HOME/.zshrc ] && echo '.zshrc symlink: OK' &&
  [ -d \$HOME/.tmux/plugins/tpm ] && echo 'tpm: OK'
"

# Interactive shell inside the container
docker run --rm -it dotfiles-test zsh
```

### Linting

Install tools:
```bash
brew install shellcheck shfmt
```

Run checks:
```bash
shellcheck install.sh bootstrap.sh   # static analysis
shfmt -d .                           # check formatting
shfmt -w .                           # auto-fix formatting
```

### CI Pipeline

Every push and pull request to `main` runs three jobs:

```
shellcheck ─┐
            ├──► test-linux (Docker)
shfmt      ─┘
```

| Job | What it does |
|---|---|
| `shellcheck` | Static analysis on all `.sh` files |
| `shfmt` | Format check on all `.sh` files |
| `test-linux` | Full install inside Docker, verifies brew / oh-my-zsh / symlinks / TPM |

## Customization

**Add a package:** edit `deps/deps-macos.txt`

```txt
# one package per line
your-package-name
```

**Add a new component:**
1. Create a folder with your config files
2. Add a `links.prop` file for any symlinks
3. Add any custom copy logic to `install.sh` if needed

## Troubleshooting

**nvim-treesitter error?**
Run `:TSInstall lua` to reinstall the parser.

**Tmux plugins not loading?**
Press `Ctrl+A, Shift+I` inside a tmux session to reinstall.

**Shell prompt not showing correctly?**
Run `source ~/.zshrc` or restart your terminal.

**Homebrew not found after install?**
Run `eval "$(/opt/homebrew/bin/brew shellenv)"` (macOS) or `eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"` (Linux).

## Requirements

- macOS or Linux
- `git` (for cloning)
- Internet connection
