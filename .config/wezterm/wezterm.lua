-- WezTerm Configuration
local wezterm = require 'wezterm'
local config = {}

-- Use config builder if available (WezTerm 20220807-113146-c2fee766 and later)
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- Terminal colors — auto-generated from active palette theme
local colors_file = os.getenv("HOME") .. "/.config/wezterm/colors.lua"
local ok, colors = pcall(dofile, colors_file)
if ok then config.colors = colors end

-- Font configuration
config.font_size = 9.0

-- Window appearance
config.window_background_opacity = 0.95

return config
