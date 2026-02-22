-- Konsole bootstrap

local function get_script_dir()
	local info = debug.getinfo(1, "S")
	local path = info.source:match("^@(.*/)")
	return path or "./"
end

local script_dir = get_script_dir()
package.path = script_dir .. "../?.lua;" .. script_dir .. "../../util/?.lua;" .. package.path

local generator = require("generator")
local linker = require("linker")

if not linker.machine() then linker.init() end

if linker.machine().os.type ~= "unix" then return end

local output = linker.resolve("konsoleConfig")
if output then
	local ok, err = generator.generate("konsole", output)
	if not ok then
		print("konsole: generation failed - " .. err)
		return
	end
end

local ok, err = linker.link_var("konsoleConfig", "systemKonsole")
if not ok and err ~= "already linked" then
	print("konsole: " .. (err or "link failed"))
end
