-- Terminal Emulator Bootstrap
-- Generates and links configs for all emulators

local function get_script_dir()
	local info = debug.getinfo(1, "S")
	local path = info.source:match("^@(.*/)")
	return path or "./"
end

local script_dir = get_script_dir()
package.path = script_dir .. "?.lua;" .. script_dir .. "../linking/?.lua;" .. package.path

local generator = require("generator")
local linker = require("linker")

if not linker.machine() then linker.init() end

local os_type = linker.machine().os.type

-- Run each emulator's bootstrap if it exists and matches OS
for _, name in ipairs(generator.list_emulators()) do
	local bootstrap_path = script_dir .. name .. "/bootstrap.lua"
	local f = io.open(bootstrap_path, "r")
	if f then
		f:close()
		dofile(bootstrap_path)
	end
end
