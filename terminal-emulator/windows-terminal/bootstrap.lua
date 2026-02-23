-- Windows Terminal bootstrap

local function get_script_dir()
	local info = debug.getinfo(1, "S")
	local source = info and info.source or ""
	local path = source:match("^@(.+[\\/])")
	if path then
		return path:gsub("\\", "/")
	end
	return "./"
end

local script_dir = get_script_dir()
package.path = script_dir .. "../../util/?.lua;" .. package.path

local linker = require("linker")

if not linker.machine() then linker.init() end

if linker.machine().os.type ~= "windows" then return end

package.path = script_dir .. "../?.lua;" .. package.path
local generator = require("generator")

local output = linker.resolve("windowsTerminalConfig")
if output then
	local ok, err = generator.generate("windows-terminal", output)
	if not ok then
		print("windows-terminal: generation failed - " .. err)
		return
	end
end

local ok, err = linker.link_var("windowsTerminalConfig", "systemWindowsTerminal")
if not ok and err ~= "already linked" then
	print("windows-terminal: " .. (err or "link failed"))
end
