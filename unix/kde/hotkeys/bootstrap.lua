local c = require("colors")

local function get_dir()
	local info = debug.getinfo(1, "S")
	return info.source:match("^@(.+/)")
end

local hotkeys_dir = get_dir()
package.path = hotkeys_dir .. "?.lua;" .. package.path

local generate = require("generate")

local function load_file(path)
	local fn, err = loadfile(path)
	if not fn then return nil, err end
	return fn()
end

local binds, err = load_file(hotkeys_dir .. "binds.lua")
if not binds then
	c.tag_err("hotkeys", "failed to load binds: " .. (err or "unknown"))
	return
end

local content = generate.generate(binds)

local generated_path = hotkeys_dir .. "generated.conf"
local f = io.open(generated_path, "w")
if not f then
	c.tag_err("hotkeys", "could not write: " .. generated_path)
	return
end
f:write(content)
f:close()
c.tag_ok("hotkeys", "generated: " .. generated_path)

local abs_handle = io.popen('realpath "' .. generated_path .. '"')
local abs_generated = abs_handle:read("*l")
abs_handle:close()

local system_path = "/etc/keyd/default.conf"
local result = os.execute(string.format('sudo ln -sf "%s" "%s"', abs_generated, system_path))
if result == 0 or result == true then
	c.tag_ok("hotkeys", "linked: " .. system_path .. " -> " .. generated_path)
	os.execute("sudo systemctl reload keyd 2>/dev/null || sudo systemctl restart keyd 2>/dev/null || true")
else
	c.tag_err("hotkeys", "could not symlink to " .. system_path)
end
