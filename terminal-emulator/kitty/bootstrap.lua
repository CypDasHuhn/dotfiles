-- Kitty bootstrap

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

if linker.machine().os.type ~= "unix" then return end

package.path = script_dir .. "../?.lua;" .. package.path
local generator = require("generator")

local output = linker.resolve("kittyConfig")
if output then
	local ok, err = generator.generate("kitty", output)
	if not ok then
		print("kitty: generation failed - " .. err)
		return
	end
end

local ok, err = linker.link_var("kittyConfig", "systemKitty")
if not ok and err ~= "already linked" then
	print("kitty: " .. (err or "link failed"))
end
