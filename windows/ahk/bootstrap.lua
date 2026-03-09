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

local source = ahk_dir .. "generated/home.ahk"
local target = startup_dir .. "/home.ahk"
local ok, err = linker.link(source, target)
if ok then
	c.tag_ok("ahk", "linked")
elseif err ~= "already linked" then
	c.tag_err("ahk", err or "link failed")
end
