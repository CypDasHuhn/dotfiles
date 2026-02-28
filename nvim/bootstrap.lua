local ok, err = require("linker").link_module("nvim")
if not ok and err ~= "already linked" then print("nvim: " .. (err or "failed")) end
