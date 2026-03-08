local c = require("colors")
local ok, err = require("linker").link_module("hyprpanel")
if ok then
	c.tag_ok("hyprpanel", "linked")
elseif err ~= "already linked" then
	c.tag_err("hyprpanel", err or "failed")
end
