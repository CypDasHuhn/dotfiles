-- Konsole Adapter (konsoleui.rc XML format)

local M = {}

M.name = "konsole"
M.config_extension = "rc"

local directions = { "Left", "Down", "Up", "Right" }

M.action_map = {
	NextTab = "next-tab",
	PreviousTab = "previous-tab",
	MoveTabLeft = "move-tab-to-left",
	MoveTabRight = "move-tab-to-right",
	NewTab = "new-tab",
	ClosePane = "close-session",      -- closes tab/session
	CloseView = "close-active-view",  -- closes split view only
	RenameTab = "rename-session",

	Copy = "edit_copy",
	Paste = "edit_paste",

	DuplicatePane = "split-view-auto",

	Find = "edit_find",
	ToggleFullscreen = "view-full-screen",
}

-- Focus pane
M.action_map.FocusPaneLeft = "focus-view-left"
M.action_map.FocusPaneDown = "focus-view-below"
M.action_map.FocusPaneUp = "focus-view-above"
M.action_map.FocusPaneRight = "focus-view-right"

-- Split pane - Konsole only has left-right and top-bottom
M.action_map.SplitPaneLeft = "split-view-left-right"
M.action_map.SplitPaneRight = "split-view-left-right"
M.action_map.SplitPaneUp = "split-view-top-bottom"
M.action_map.SplitPaneDown = "split-view-top-bottom"

-- Tab access
for i = 1, 9 do
	M.action_map["Tab" .. i] = "switch-to-tab-" .. (i - 1)
end

-- Parse key syntax to KDE format: "ctrl+shift+t" -> "Ctrl+Shift+T"
function M.parse_key(key)
	local parts = {}
	for part in key:gmatch("[^+]+") do
		local cap
		if part:lower() == "pageup" then cap = "PgUp"
		elseif part:lower() == "pagedown" then cap = "PgDown"
		elseif #part == 1 then cap = part:upper()
		else cap = part:sub(1,1):upper() .. part:sub(2):lower()
		end
		table.insert(parts, cap)
	end
	return table.concat(parts, "+")
end

function M.generate(keybinds)
	local entries = {}
	local seen = {}

	local action_names = {}
	for name in pairs(keybinds) do
		if M.action_map[name] then
			table.insert(action_names, name)
		end
	end
	table.sort(action_names)

	for _, name in ipairs(action_names) do
		local action = M.action_map[name]
		local key = M.parse_key(keybinds[name])
		if not seen[action] then
			table.insert(entries, string.format('  <Action name="%s" shortcut="%s"/>', action, key))
			seen[action] = true
		end
	end

	return ' <ActionProperties scheme="Default">\n' .. table.concat(entries, "\n") .. '\n </ActionProperties>'
end

return M
