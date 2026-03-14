-- WezTerm Adapter (wezterm.lua format)

local M = {}

M.name = "wezterm"
M.config_extension = "lua"

M.action_map = {
	NextTab = 'act.ActivateTabRelative(1)',
	PreviousTab = 'act.ActivateTabRelative(-1)',
	NewTab = 'act.SpawnTab "CurrentPaneDomain"',
	ClosePane = 'act.CloseCurrentPane { confirm = false }',
	RenameTab = 'act.PromptInputLine { description = "Rename tab", action = wezterm.action_callback(function(w, _, line) if line then w:active_tab():set_title(line) end end) }',

	Copy = 'act.CopyTo "Clipboard"',
	Paste = 'act.PasteFrom "Clipboard"',

	DuplicatePane = 'act.SplitPane { direction = "Right" }',

	Find = 'act.Search "CurrentSelectionOrEmptyString"',
	CommandPalette = 'act.ActivateCommandPalette',
	ToggleFullscreen = 'act.ToggleFullScreen',
}

-- Focus pane
M.action_map.FocusPaneLeft = 'act.ActivatePaneDirection "Left"'
M.action_map.FocusPaneDown = 'act.ActivatePaneDirection "Down"'
M.action_map.FocusPaneUp = 'act.ActivatePaneDirection "Up"'
M.action_map.FocusPaneRight = 'act.ActivatePaneDirection "Right"'

-- Split pane
M.action_map.SplitPaneLeft = 'act.SplitPane { direction = "Left" }'
M.action_map.SplitPaneRight = 'act.SplitPane { direction = "Right" }'
M.action_map.SplitPaneUp = 'act.SplitPane { direction = "Up" }'
M.action_map.SplitPaneDown = 'act.SplitPane { direction = "Down" }'

-- Resize pane
M.action_map.ResizePaneLeft = 'act.AdjustPaneSize { "Left", 5 }'
M.action_map.ResizePaneRight = 'act.AdjustPaneSize { "Right", 5 }'
M.action_map.ResizePaneUp = 'act.AdjustPaneSize { "Up", 5 }'
M.action_map.ResizePaneDown = 'act.AdjustPaneSize { "Down", 5 }'

-- Tab access
for i = 1, 9 do
	M.action_map["Tab" .. i] = "act.ActivateTab(" .. (i - 1) .. ")"
end

-- Parse key syntax to WezTerm format: "ctrl+shift+t" -> key="t", mods="CTRL|SHIFT"
function M.parse_key(key)
	local mods = {}
	local main_key = nil

	for part in key:gmatch("[^+]+") do
		local lower = part:lower()
		if lower == "ctrl" then
			table.insert(mods, "CTRL")
		elseif lower == "shift" then
			table.insert(mods, "SHIFT")
		elseif lower == "alt" then
			table.insert(mods, "ALT")
		elseif lower == "super" or lower == "win" then
			table.insert(mods, "SUPER")
		elseif lower == "left" then main_key = "LeftArrow"
		elseif lower == "right" then main_key = "RightArrow"
		elseif lower == "up" then main_key = "UpArrow"
		elseif lower == "down" then main_key = "DownArrow"
		elseif lower == "pageup" then main_key = "PageUp"
		elseif lower == "pagedown" then main_key = "PageDown"
		elseif lower:match("^f%d+$") then main_key = lower:upper()
		else main_key = part
		end
	end

	local mods_str = #mods > 0 and table.concat(mods, "|") or "NONE"
	return main_key, mods_str
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
		local key, mods = M.parse_key(keybinds[name])
		table.insert(entries, string.format(
			'  { key = %q, mods = %q, action = %s },',
			key, mods, action
		))
	end

	return table.concat(entries, "\n")
end

return M
