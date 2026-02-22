local keybinds = {}
local mod = "alt+shift+"

local directions = {
	Left = { vim = "h", arrow = "left" },
	Down = { vim = "j", arrow = "down" },
	Up = { vim = "k", arrow = "up" },
	Right = { vim = "l", arrow = "right" },
}

local function directional(prefix, modifier, style)
	for dir, keys in pairs(directions) do
		keybinds[prefix .. dir] = modifier .. keys[style]
	end
end

directional("FocusPane", "alt+", "vim")
directional("SplitPane", mod, "arrow")
directional("ResizePane", "ctrl+" .. mod, "arrow")

keybinds.NextTab = mod .. "l"
keybinds.PreviousTab = mod .. "h"
keybinds.NewTab = mod .. "t"
keybinds.ClosePane = mod .. "w"
keybinds.RenameTab = mod .. "r"

for i = 1, 9 do
	keybinds["Tab" .. i] = mod .. i
end

keybinds.Copy = "shift+ctrl+c"
keybinds.Paste = "shift+ctrl+v"

keybinds.DuplicatePane = mod .. "d"

-- Misc
keybinds.Find = "ctrl+shift+f"
keybinds.CommandPalette = mod .. "p"
keybinds.ToggleFullscreen = "f11"

return keybinds
