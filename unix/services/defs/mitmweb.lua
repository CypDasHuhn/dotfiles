local allow_hosts = {
	"(^|\\.)reddit\\.com(:[0-9]+)?$",
}

local function flag(name, values)
	local args = {}
	for _, value in ipairs(values) do
		table.insert(args, name)
		table.insert(args, value)
	end
	return args
end

local function concat(parts)
	local args = {}
	for _, part in ipairs(parts) do
		for _, value in ipairs(part) do
			table.insert(args, value)
		end
	end
	return args
end

local command = concat({
	{ "mitmdump", "--quiet", "--listen-host", "127.0.0.1", "--listen-port", "8080" },
	flag("--allow-hosts", allow_hosts),
	{ "-s", "~/.config/mitmproxy/reddit_filter.py", "--set", "ssl_insecure=true" },
})

return {
	name = "mitmweb",
	description = "Headless mitmproxy",
	command = command,
	restart = "on-failure",
	environment = {
		PYTHONPYCACHEPREFIX = "${HOME}/.cache/python",
	},
	wanted_by = "default.target",
	only = { os = "unix" },
}
