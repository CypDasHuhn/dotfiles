local c = require("colors")
local ok, err = require("linker").link_module("mitmproxy")
if ok then
	c.tag_ok("mitmproxy", "linked")
elseif err ~= "already linked" then
	c.tag_err("mitmproxy", err or "failed")
end
