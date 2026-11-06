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

The installation script is **idempotent** — safe to run multiple times. By default it prints one summary line per step:

```
dotfiles · darwin · ~/dotfiles

[1/3] packages  ✓ 17 present, nothing to install                             2s
[2/3] links     ✓ 9 up to date                                               <1s
[3/3] plugins   ✓ 2 sheldon, 6 tmux plugins                                  <1s

Done in 2s. Open a new terminal, or run: source ~/.zshrc
```

| Command | What it does |
|---|---|
| `./install.sh` | run every step (quiet summary) |
| `./install.sh -v` | also show every detail and the tools' own output |
| `./install.sh -n` | **dry run**: show what would be installed, linked or backed up, and change nothing |
| `./install.sh links` | run one step: `packages`, `links` or `plugins` (they can be combined, e.g. `-n links plugins`) |
| `./install.sh --help` | usage |

If a step fails, its last log lines are printed under it, the other steps still run, and the exit status is non-zero. `NO_COLOR=1` turns colors off; output is plain when it isn't a terminal.

## What's Included

| Tool | Description |
|---|---|
| **Zsh + sheldon** | Shell with plugins (autosuggestions, syntax highlighting); per-machine overrides in `~/.zshrc.local` |
| **Neovim** | Modern Vim with LazyVim configuration |
| **Tmux** | Terminal multiplexer with TPM plugins |
| **Starship** | Fast, customizable shell prompt |
| **LazyGit** | Terminal UI for Git |
| **Alacritty** | GPU-accelerated terminal emulator |
| **WezTerm** | Cross-platform terminal emulator |
| **VS Code** | Editor settings and configuration |

## Installation Process

`install.sh` runs three steps, in order:

1. **packages** — installs Homebrew if needed, then everything in the `Brewfile` with `brew bundle` (missing packages only; nothing is upgraded). Casks, such as the Nerd Font, Alacritty, WezTerm and VS Code, are installed on macOS only.
2. **links** — creates symlinks from every `links.prop` (all OSes) and `links.<os>.prop` (`darwin` or `linux`) in the component folders.
3. **plugins** — downloads the sheldon plugins and installs TPM and the tmux plugins.

A failing step doesn't abort the others; all failures are listed at the end and the exit status is non-zero.

**When a destination file already exists**, the script asks what to do (backup / overwrite / skip, capital letter = all). With no terminal (CI, `curl | bash`) it backs the file up to `<file>.backup.<timestamp>` instead of skipping it. Override with `DOTFILES_ON_CONFLICT=backup|overwrite|skip`.

## Repository Structure

```
dotfiles/
├── bootstrap.sh            # One-liner entry point (clones repo + runs install.sh)
├── install.sh              # Main installation script
├── Dockerfile.test         # Docker image for local testing
├── Brewfile                # Homebrew packages, casks and fonts
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
├── sheldon/
│   ├── plugins.toml
│   └── links.prop
├── starship/
│   ├── starship.toml
│   └── links.prop
├── tmux/
│   └── links.prop
├── lazygit/
│   ├── config.yml
│   ├── links.darwin.prop   # macOS reads ~/Library/Application Support/lazygit
│   └── links.linux.prop    # Linux reads ~/.config/lazygit
├── vscode/
│   ├── settings.json
│   ├── vscode_init.vim
│   ├── links.darwin.prop
│   └── links.linux.prop
└── wezterm/
    ├── wezterm.lua
    └── colors/
```

## Symlinks (via `links.prop`)

Each component folder contains a `links.prop` file defining mappings in the form `$DOTFILES/path=$HOME/path`. Only `$DOTFILES` and `$HOME` are expanded, and paths may contain spaces. Use `links.darwin.prop` or `links.linux.prop` for entries that only apply to one OS.

| Source | Destination |
|---|---|
| `zsh/.zshrc` | `~/.zshrc` |
| `sheldon/plugins.toml` | `~/.config/sheldon/plugins.toml` |
| `alacritty/alacritty.toml` | `~/.config/alacritty/alacritty.toml` |
| `lazyvim/` | `~/.config/nvim` |
| `starship/starship.toml` | `~/.config/starship/starship.toml` |
| `tmux/.tmux.conf` | `~/.tmux.conf` |
| `lazygit/config.yml` | macOS: `~/Library/Application Support/lazygit/config.yml`, Linux: `~/.config/lazygit/config.yml` |
| `vscode/settings.json` | macOS: `~/Library/Application Support/Code/User/settings.json`, Linux: `~/.config/Code/User/settings.json` |

## Machine-specific settings

`~/.zshrc` is a symlink to the shared `zsh/.zshrc`, so avoid editing it per machine. Instead, create `~/.zshrc.local`; it is sourced last, is never tracked or overwritten by `install.sh`, and can override anything. Use it for work-only paths, env vars and secrets:

```zsh
# ~/.zshrc.local
export PATH="$HOME/work/bin:$PATH"
alias k="kubectl"
```

## Testing

### Local (Docker)

```bash
# Full install smoke test
docker build -f Dockerfile.test -t dotfiles-test .

# Verify installation
docker run --rm dotfiles-test zsh -c "
  eval \"\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\" &&
  brew --version && echo 'brew: OK' &&
  brew list sheldon >/dev/null && echo 'sheldon: OK' &&
  command -v starship >/dev/null && echo 'starship: OK' &&
  command -v delta >/dev/null && echo 'delta: OK' &&
  [ -L \$HOME/.zshrc ] && echo '.zshrc symlink: OK' &&
  [ -L \$HOME/.config/lazygit/config.yml ] && echo 'lazygit config link: OK' &&
  [ -z \"\$(zsh -i -c exit 2>&1)\" ] && echo 'zsh starts without errors: OK' &&
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
| `test-linux` | Full install inside Docker, verifies brew / sheldon / starship / symlinks / TPM |

## Customization

**Add a package:** edit the `Brewfile`

```ruby
brew "your-package-name"
cask "your-app"            # macOS only: put inside `if OS.mac?`
```

Check it with `brew bundle check --file=Brewfile`.

**Add a new component:**
1. Create a folder with your config files
2. Add a `links.prop` file (or `links.darwin.prop` / `links.linux.prop`) for the symlinks

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
