local wezterm = require "wezterm"
local act = wezterm.action

local config = wezterm.config_builder()

-- Font
config.font = wezterm.font "monospace"
config.font_size = 12.0

-- Window
config.initial_cols = 120
config.initial_rows = 40

-- Tab bar
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false

-- Bell
config.audible_bell = "Disabled"

-- Scrollback
config.scrollback_lines = 10000

-- Cursor
config.default_cursor_style = "BlinkingBlock"

-- Clear default keybinds and use generated ones
config.disable_default_key_bindings = true

config.keys = {
-- KEYBINDS-REPLACE
}

return config
