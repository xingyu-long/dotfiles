## Neovim Setup


```
# install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# neo-vim
brew install neovim

# iterm2 (macOS only)
brew install --cask iterm2

# Ripgrep for nvim to do the search
brew install ripgrep

# node
brew install node

# download the project
git clone https://github.com/xingyu-long/dotfiles.git
cp -r dotfiles/nvim  ~/.config/nvim

# give it a try
cd ~/.config/nvim/lua/xlong
nvim plugins-setup.lua # once you opened it, Packer will install plugins

# Using NvChad
git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1 && nvim
# finish the packer and load custom folder into NvChad
cp -r ./nvchad_custom_config/custom ~/.config/nvim/lua/

```

## Tmux Setup

```
cp dotfiles/.tmux.conf ~/.tmux.conf

# install tmux plugins manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

tmux source ~/.tmux.conf

# use tmux to create the session
tmux new -s test_session
# install all plugins through tpm
# Ctrl, A, shift, i

```

## FAQ

- Q: nvim-treesitter error when use nvim?
  - A: please run `:TSInstall lua` to reinstall the parser.
