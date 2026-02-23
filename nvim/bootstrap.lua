-- nvim bootstrap
-- Links dotfiles/nvim to system nvim config location

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

-- Load linker (already initialized by root bootstrap)
package.path = script_dir .. "../util/?.lua;" .. package.path
local linker = require("linker")

-- Ensure linker is initialized (in case running standalone)
if not linker.machine() then
	linker.init()
end

-- Link nvim -> systemNvim
local ok, err = linker.link_module("nvim")
if not ok and err ~= "already linked" then
	print("nvim: " .. (err or "failed"))
end
