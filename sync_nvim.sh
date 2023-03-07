
if [ $1 = "push" ]; then
  # copy config from ~/.config/nvim to . and save as commit
  cp -r ~/.config/nvim/lua/custom/* ./nvchad_custom_config/custom
  git add .
  git commit
elif [ $1 == "get" ]; then
  # copy config from git repo to local config dir
  git pull --rebase
  rm -rf ~/.config/nvim/lua/custom
  cp -r ./nvchad_custom_config/custom ~/.config/nvim/lua
  cd ~/.config/nvim && nvim .
else
  echo "wrong argument"
fi
