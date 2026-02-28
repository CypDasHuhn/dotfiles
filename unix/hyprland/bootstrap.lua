local ok, err = require("linker").link_module("hyprland")
if not ok and err ~= "already linked" then print("hyprland: " .. (err or "failed")) end
