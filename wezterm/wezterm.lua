local wezterm = require("wezterm")
local config = {}

config.color_scheme = "Dracula (Official)"

-- config.font_size = 18.0
config.font_size = 22.0
config.font = wezterm.font("JetBrainsMono Nerd Font", { weight = "Bold" })

config.window_decorations = "RESIZE"
config.use_resize_increments = true
config.window_padding = {
  left = 2,
  right = 2,
  top = 0,
  bottom = 0,
}

return config
