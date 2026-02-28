local actions = {
	focus = function(target)
		return "kdotool search -n '" .. target .. "' windowactivate"
	end,
	open = function(target)
		return target
	end,
}

local function mod_count(hold)
	local n = 0
	for _ in hold:gmatch("[^+]+") do n = n + 1 end
	return n
end

local function extra_mod(from_hold, to_hold)
	local have = {}
	for m in from_hold:gmatch("[^+]+") do have[m] = true end
	for m in to_hold:gmatch("[^+]+") do
		if not have[m] then return m end
	end
end

local function layer_name(base, hold)
	return base .. "_" .. hold:gsub("+", "_")
end

local M = {}

function M.generate(config)
	local lyr = config.layer
	local binds = config.binds

	local by_hold, holds = {}, {}
	for _, bind in ipairs(binds) do
		if not by_hold[bind.hold] then
			by_hold[bind.hold] = {}
			table.insert(holds, bind.hold)
		end
		table.insert(by_hold[bind.hold], bind)
	end
	table.sort(holds, function(a, b) return mod_count(a) < mod_count(b) end)
	for _, hold in ipairs(holds) do
		table.sort(by_hold[hold], function(a, b) return a.key < b.key end)
	end

	local user = os.getenv("USER") or "cyp"
	local uid_handle = io.popen("id -u " .. user)
	local uid = uid_handle and uid_handle:read("*l") or "1000"
	if uid_handle then uid_handle:close() end

	local function wrap_cmd(cmd)
		return string.format(
			'su -c "WAYLAND_DISPLAY=wayland-0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/%s/bus %s" %s',
			uid, cmd, user
		)
	end

	local lines = {
		"[ids]",
		"*",
		"",
		"[main]",
		lyr.key .. " = layer(" .. layer_name(lyr.name, holds[1]) .. ")",
		"",
	}

	for i, hold in ipairs(holds) do
		local lname = layer_name(lyr.name, hold)
		table.insert(lines, "[" .. lname .. ":" .. hold .. "]")

		if holds[i + 1] then
			local via = extra_mod(hold, holds[i + 1])
			if via then
				table.insert(lines, via .. " = layer(" .. layer_name(lyr.name, holds[i + 1]) .. ")")
			end
		end

		for _, bind in ipairs(by_hold[hold]) do
			local action_fn = actions[bind.action]
			if not action_fn then error("Unknown action: " .. bind.action) end
			table.insert(lines, bind.key .. " = command(" .. wrap_cmd(action_fn(bind.target)) .. ")")
		end

		table.insert(lines, "")
	end

	return table.concat(lines, "\n")
end

return M
