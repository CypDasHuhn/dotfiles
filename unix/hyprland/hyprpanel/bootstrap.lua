-- hyprpanel bootstrap
-- Links dotfiles/unix/hyprland/hyprpanel to system hyprpanel config location

local script_dir = arg[0]:match("(.*/)")
if not script_dir then
	script_dir = "./"
end

-- Load linker (already initialized by root bootstrap)
package.path = script_dir .. "../../../util/?.lua;" .. package.path
local linker = require("linker")

-- Ensure linker is initialized (in case running standalone)
if not linker.machine() then
	linker.init()
end

-- Link hyprpanel -> systemHyprpanel
local ok, err = linker.link_module("hyprpanel")
if not ok and err ~= "already linked" then
	print("hyprpanel: " .. (err or "failed"))
end
