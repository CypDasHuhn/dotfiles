local c = require("colors")
local ok, err = require("linker").link_module("hyprland")
if ok then
	c.tag_ok("hyprland", "linked")
elseif err ~= "already linked" then
	c.tag_err("hyprland", err or "failed")
end
