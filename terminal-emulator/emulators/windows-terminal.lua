-- Windows Terminal Adapter
-- Config: %LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_*\LocalState\settings.json

local M = {}

M.name = "windows-terminal"
M.config_extension = "json"

-- Map our action names to Windows Terminal commands
M.action_map = {
	-- Tab navigation
	NextTab = "nextTab",
	PreviousTab = "prevTab",
	NewTab = "newTab",
	CloseTab = "closeTab",

	-- Tab direct access (these need index parameter)
	Tab1 = { action = "switchToTab", index = 0 },
	Tab2 = { action = "switchToTab", index = 1 },
	Tab3 = { action = "switchToTab", index = 2 },
	Tab4 = { action = "switchToTab", index = 3 },
	Tab5 = { action = "switchToTab", index = 4 },
	Tab6 = { action = "switchToTab", index = 5 },
	Tab7 = { action = "switchToTab", index = 6 },
	Tab8 = { action = "switchToTab", index = 7 },
	Tab9 = { action = "switchToTab", index = 8 },

	-- Pane/Split management
	SplitVertical = { action = "splitPane", split = "right" },
	SplitHorizontal = { action = "splitPane", split = "down" },
	ClosePane = "closePane",
	FocusPaneLeft = { action = "moveFocus", direction = "left" },
	FocusPaneRight = { action = "moveFocus", direction = "right" },
	FocusPaneUp = { action = "moveFocus", direction = "up" },
	FocusPaneDown = { action = "moveFocus", direction = "down" },

	-- Clipboard
	Copy = "copy",
	Paste = "paste",

	-- Scrolling
	ScrollUp = "scrollUp",
	ScrollDown = "scrollDown",
	ScrollPageUp = "scrollUpPage",
	ScrollPageDown = "scrollDownPage",

	-- Font size
	FontIncrease = { action = "adjustFontSize", delta = 1 },
	FontDecrease = { action = "adjustFontSize", delta = -1 },
	FontReset = "resetFontSize",

	-- Misc
	Find = "find",
	ToggleFullscreen = "toggleFullscreen",
}

-- Parse our key syntax to Windows Terminal syntax
-- Input: "ctrl+shift+t" or "alt+h"
-- Output: "ctrl+shift+t" (Windows Terminal uses same format, just lowercase)
function M.parse_key(key)
	return key:lower()
end

-- Generate a single keybind entry
function M.format_entry(action_name, key, command)
	local keys_str = M.parse_key(key)

	if type(command) == "table" then
		-- Complex command with parameters
		local parts = {}
		for k, v in pairs(command) do
			if type(v) == "string" then
				table.insert(parts, string.format('"%s": "%s"', k, v))
			else
				table.insert(parts, string.format('"%s": %s', k, tostring(v)))
			end
		end
		-- Sort for consistent output
		table.sort(parts)
		return string.format('        { "command": { %s }, "keys": "%s" }', table.concat(parts, ", "), keys_str)
	else
		-- Simple command
		return string.format('        { "command": "%s", "keys": "%s" }', command, keys_str)
	end
end

-- Generate the full keybinds block
function M.generate(keybinds)
	local entries = {}

	-- Collect and sort action names for consistent output
	local action_names = {}
	for name in pairs(keybinds) do
		if M.action_map[name] then
			table.insert(action_names, name)
		end
	end
	table.sort(action_names)

	for _, name in ipairs(action_names) do
		local key = keybinds[name]
		local command = M.action_map[name]
		table.insert(entries, M.format_entry(name, key, command))
	end

	return '    "actions": [\n' .. table.concat(entries, ",\n") .. "\n    ]"
end

return M
