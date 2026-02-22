-- Kitty Adapter (kitty.conf format)

local M = {}

M.name = "kitty"
M.config_extension = "conf"

M.action_map = {
	NextTab = "next_tab",
	PreviousTab = "previous_tab",
	NewTab = "new_tab",
	ClosePane = "close_window",
	RenameTab = "set_tab_title",

	Copy = "copy_to_clipboard",
	Paste = "paste_from_clipboard",

	DuplicatePane = "launch --location=split",

	Find = "show_scrollback",
	CommandPalette = "kitty_shell window",
	ToggleFullscreen = "toggle_fullscreen",
}

-- Focus pane (neighboring_window)
M.action_map.FocusPaneLeft = "neighboring_window left"
M.action_map.FocusPaneDown = "neighboring_window down"
M.action_map.FocusPaneUp = "neighboring_window up"
M.action_map.FocusPaneRight = "neighboring_window right"

-- Split pane
M.action_map.SplitPaneLeft = "launch --location=vsplit"
M.action_map.SplitPaneRight = "launch --location=vsplit"
M.action_map.SplitPaneUp = "launch --location=hsplit"
M.action_map.SplitPaneDown = "launch --location=hsplit"

-- Resize pane
M.action_map.ResizePaneLeft = "resize_window narrower"
M.action_map.ResizePaneRight = "resize_window wider"
M.action_map.ResizePaneUp = "resize_window taller"
M.action_map.ResizePaneDown = "resize_window shorter"

-- Tab access
for i = 1, 9 do
	M.action_map["Tab" .. i] = "goto_tab " .. i
end

-- Parse key syntax to Kitty format: "ctrl+shift+t" -> "ctrl+shift+t"
-- Kitty uses lowercase, similar to our input format
function M.parse_key(key)
	local parts = {}
	for part in key:gmatch("[^+]+") do
		-- Normalize modifier names
		local normalized = part:lower()
		if normalized == "pageup" then normalized = "page_up"
		elseif normalized == "pagedown" then normalized = "page_down"
		end
		table.insert(parts, normalized)
	end
	return table.concat(parts, "+")
end

function M.generate(keybinds)
	local entries = {}

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
		table.insert(entries, string.format("map %s %s", key, action))
	end

	return table.concat(entries, "\n")
end

return M
