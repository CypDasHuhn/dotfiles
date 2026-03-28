local c = require("colors")
local ok, err = require("linker").link_module("zellij")
if ok then
	c.tag_ok("zellij", "linked")
elseif err ~= "already linked" then
	c.tag_err("zellij", err or "failed")
end
