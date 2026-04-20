local c = require("colors")
local ok, err = require("linker").link_module("lazygit")
if ok then
	c.tag_ok("lazygit", "linked")
elseif err ~= "already linked" then
	c.tag_err("lazygit", err or "failed")
end
