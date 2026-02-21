-- Windows Terminal Adapter

local M = {}

M.name = "windows-terminal"
M.config_extension = "json"

local directions = { "Left", "Down", "Up", "Right" }

local function directional(ours, theirs)
	for _, dir in ipairs(directions) do
		M.action_map[ours .. dir] = "Terminal." .. theirs .. dir
	end
end

M.action_map = {
	NextTab = "Terminal.NextTab",
	PreviousTab = "Terminal.PrevTab",
	NewTab = "Terminal.OpenNewTab",
	ClosePane = "Terminal.ClosePane",
	RenameTab = "Terminal.OpenTabRenamer",

	Copy = "Terminal.CopyToClipboard",
	Paste = "Terminal.PasteFromClipboard",

	DuplicatePane = "Terminal.DuplicatePaneAuto",

	Find = "Terminal.FindText",
	CommandPalette = "Terminal.ToggleCommandPalette",
	ToggleFullscreen = "Terminal.ToggleFullscreen",
}

directional("FocusPane", "MoveFocus")
directional("SplitPane", "SplitPane")
directional("ResizePane", "ResizePane")

for i = 1, 9 do
	M.action_map["Tab" .. i] = "Terminal.SwitchToTab" .. (i - 1)
end

function M.parse_key(key)
	return key:lower()
end

function M.format_entry(action_name, key, action_id)
	return string.format('    { "id": "%s", "keys": "%s" }', action_id, M.parse_key(key))
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
		table.insert(entries, M.format_entry(name, keybinds[name], M.action_map[name]))
	end

	return '  "actions": [\n' .. table.concat(entries, ",\n") .. "\n  ],"
end

return M
