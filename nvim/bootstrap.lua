-- nvim bootstrap
-- Links dotfiles/nvim to system nvim config location

local script_dir = arg[0]:match("(.*/)")
if not script_dir then
	script_dir = "./"
end

-- Load linker (already initialized by root bootstrap)
package.path = script_dir .. "../linking/?.lua;" .. package.path
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
