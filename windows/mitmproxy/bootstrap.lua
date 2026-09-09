local c = require("colors")
local linker = require("linker")

local ok, err = linker.link_module("mitmproxy")
if ok then
	c.tag_ok("mitmproxy", "config linked")
elseif err ~= "already linked" then
	c.tag_err("mitmproxy", err or "config link failed")
	return
end

local source_info = debug.getinfo(1, "S").source
local source_dir = source_info:match("^@(.+[\\/])")
if not source_dir then
	c.tag_err("mitmproxy", "could not resolve launcher path")
	return
end

local startup_dir = linker.resolve("startup")
if not startup_dir then
	c.tag_err("mitmproxy", "could not resolve Startup folder")
	return
end

local launcher = source_dir:gsub("\\", "/") .. "mitmweb.vbs"
local target = startup_dir .. "/mitmweb.vbs"
local launcher_ok, launcher_err = linker.link(launcher, target)
if launcher_ok then
	c.tag_ok("mitmproxy", "starts at login")
elseif launcher_err ~= "already linked" then
	c.tag_err("mitmproxy", launcher_err or "launcher link failed")
end
