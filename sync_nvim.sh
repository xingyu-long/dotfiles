git pull --rebase
rm -rf ~/.config/nvim/lua/custom
cp -r ./nvchad_custom_config/custom ~/.config/nvim/lua
cd ~/.config/nvim && nvim .
