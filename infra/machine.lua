local platform = require("platform")
local c = require("colors")

local M = {}

local function prompt(message)
	io.write(message)
	io.flush()
	local input = io.read("*l")
	return input and input:match("^%s*(.-)%s*$")
end

function M.ensure(script_dir)
	local machine_path = script_dir .. ".machine.local.lua"
	local f = io.open(machine_path, "r")
	if f then
		f:close()
		return true
	end

	c.header("Machine Setup")
	print("")
	c.info("No .machine.local.lua found. Let's create one.")
	print("")

	local os_type = platform.os_type()
	c.info("Detected OS: " .. os_type)

	local name = prompt("Enter a name for this machine: ")
	if not name or name == "" then
		c.err("Machine name is required")
		os.exit(1)
	end

	local config = string.format(
		[[return {
	name = "%s",
	os = {
		type = "%s",
	},
}
]],
		name,
		os_type
	)

	local out = io.open(machine_path, "w")
	if not out then
		c.err("Could not write to " .. machine_path)
		os.exit(1)
	end
	out:write(config)
	out:close()

	print("")
	c.ok("Created: " .. machine_path)
	print("")

	return true
end

return M
