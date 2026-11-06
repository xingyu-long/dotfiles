# Brewfile - installed by install.sh via `brew bundle`
#
#   brew bundle check --file=Brewfile     # what is missing?
#   brew bundle --file=Brewfile           # install everything
#   brew bundle list --file=Brewfile      # list entries

# Shell
brew "sheldon"          # plugin manager (sheldon/plugins.toml)
brew "starship"         # prompt (starship/starship.toml)
brew "fzf"
brew "tmux"

# Editor and git
brew "neovim"
brew "tree-sitter-cli"  # needed by LazyVim v15
brew "lazygit"
brew "git-delta"        # pager used by lazygit/config.yml

# General tools
brew "gnupg"
brew "node"
brew "ripgrep"
brew "tree"
brew "uv"
brew "wget"

# macOS apps and fonts (casks do not exist on Linux)
if OS.mac?
  cask "font-jetbrains-mono-nerd-font"
  cask "wezterm"
  brew "mole"
end
