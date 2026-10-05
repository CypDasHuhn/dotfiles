local c = require("colors")

local function get_dir()
	local info = debug.getinfo(1, "S")
	local path = info.source:match("^@(.+[\\/])")
	return path and path:gsub("\\", "/") or "./"
end

local ahk_dir = get_dir()
local run_path = ahk_dir .. "run.lua"

local result = os.execute('lua "' .. run_path .. '"')
if result ~= 0 and result ~= true then
	c.tag_err("ahk", "generation failed")
	return
end

local linker = require("linker")
local startup_dir = linker.resolve("startup")
if not startup_dir then
	c.tag_err("ahk", "could not resolve startup directory")
	return
end

-- Windows 11 build 26200+ skips symlinked autostart entries, so link the
-- generated script as a real .lnk shortcut instead. Clear the legacy symlink
-- (and its backup) left behind by earlier versions.
local source = ahk_dir .. "generated/home.ahk"
linker.remove(startup_dir .. "/home.ahk")
linker.remove(startup_dir .. "/home.ahk.dotbak")
local target = startup_dir .. "/home.ahk.lnk"
local ok, err = linker.link_shortcut(source, target)
if ok then
	c.tag_ok("ahk", "linked")
elseif err ~= "already linked" then
	c.tag_err("ahk", err or "link failed")
end
