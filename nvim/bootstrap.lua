local c = require("colors")
local ok, err = require("linker").link_module("nvim")
if ok then
    c.tag_ok("nvim", "linked")
elseif err ~= "already linked" then
    c.tag_err("nvim", err or "failed")
end
