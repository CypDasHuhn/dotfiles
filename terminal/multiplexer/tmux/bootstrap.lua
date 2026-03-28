local c = require("colors")
local ok, err = require("linker").link_module("tmux")
if ok then
	c.tag_ok("tmux", "linked")
elseif err ~= "already linked" then
	c.tag_err("tmux", err or "failed")
end
