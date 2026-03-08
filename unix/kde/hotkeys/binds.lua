local layer = { key = "rightshift", name = "mymod" }

local apps = {
	a = "zen",
	t = "kitty",
	d = "discord",
	f = "dolphin",
	o = "obsidian",
}

local combos = {
	{ hold = "alt", action = "focus" },
	{ hold = "alt+ctrl", action = "open" },
}

local binds = {}
for _, combo in ipairs(combos) do
	for key, target in pairs(apps) do
		table.insert(binds, { hold = combo.hold, action = combo.action, key = key, target = target })
	end
end

return { layer = layer, binds = binds }
