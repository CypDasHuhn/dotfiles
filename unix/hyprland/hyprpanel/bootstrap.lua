local ok, err = require("linker").link_module("hyprpanel")
if not ok and err ~= "already linked" then print("hyprpanel: " .. (err or "failed")) end
