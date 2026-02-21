-- Konsole Adapter
-- Config: ~/.local/share/konsole/<profile>.shortcuts or ~/.config/konsolerc

local M = {}

M.name = "konsole"
M.config_extension = "shortcuts"

-- Map our action names to Konsole action names
-- These are KDE action identifiers used in .shortcuts files
M.action_map = {
	-- Tab navigation
	NextTab = "next-view",
	PreviousTab = "previous-view",
	NewTab = "new-tab",
	CloseTab = "close-session",

	-- Tab direct access (Konsole uses activate-tab-N actions, 0-indexed internally but 1-indexed in names)
	Tab1 = "activate-tab-0",
	Tab2 = "activate-tab-1",
	Tab3 = "activate-tab-2",
	Tab4 = "activate-tab-3",
	Tab5 = "activate-tab-4",
	Tab6 = "activate-tab-5",
	Tab7 = "activate-tab-6",
	Tab8 = "activate-tab-7",
	Tab9 = "activate-tab-8",

	-- Pane/Split management
	SplitVertical = "split-view-left-right",
	SplitHorizontal = "split-view-top-bottom",
	ClosePane = "close-session",
	FocusPaneLeft = "focus-view-left",
	FocusPaneRight = "focus-view-right",
	FocusPaneUp = "focus-view-above",
	FocusPaneDown = "focus-view-below",

	-- Clipboard
	Copy = "edit_copy",
	Paste = "edit_paste",

	-- Scrolling
	ScrollUp = "scroll-line-up",
	ScrollDown = "scroll-line-down",
	ScrollPageUp = "scroll-page-up",
	ScrollPageDown = "scroll-page-down",

	-- Font size
	FontIncrease = "enlarge-font",
	FontDecrease = "shrink-font",
	FontReset = "reset-font-size",

	-- Misc
	Find = "edit_find",
	ToggleFullscreen = "fullscreen",
}

-- Parse our key syntax to Konsole/KDE syntax
-- Input: "ctrl+shift+t"
-- Output: "Ctrl+Shift+T"
function M.parse_key(key)
	local parts = {}
	for part in key:gmatch("[^+]+") do
		-- Capitalize first letter of each part
		local capitalized = part:sub(1, 1):upper() .. part:sub(2):lower()
		-- Handle special cases
		if capitalized == "Ctrl" then
			capitalized = "Ctrl"
		elseif capitalized == "Alt" then
			capitalized = "Alt"
		elseif capitalized == "Shift" then
			capitalized = "Shift"
		elseif capitalized == "Pageup" then
			capitalized = "PgUp"
		elseif capitalized == "Pagedown" then
			capitalized = "PgDown"
		elseif capitalized == "Plus" then
			capitalized = "+"
		elseif capitalized == "Minus" then
			capitalized = "-"
		elseif #capitalized == 1 then
			capitalized = capitalized:upper()
		end
		table.insert(parts, capitalized)
	end
	return table.concat(parts, "+")
end

-- Generate a single keybind entry
function M.format_entry(action_name, key, command)
	local keys_str = M.parse_key(key)
	return string.format("%s=%s", command, keys_str)
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

	table.insert(entries, "[Shortcuts]")
	for _, name in ipairs(action_names) do
		local key = keybinds[name]
		local command = M.action_map[name]
		table.insert(entries, M.format_entry(name, key, command))
	end

	return table.concat(entries, "\n")
end

return M
