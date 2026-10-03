-- Seafile sync client.
--   Unix    -> `seafile` AUR package (provides seaf-cli + seaf-cli@.service)
--   Windows -> `Seafile.Seafile` via winget (GUI sync client)
local h = require("infra.dependencies.helpers")

return {
	seafile = h.dep({
			unix = h.yay("seafile", "seaf-cli"),
			windows = h.winget("Seafile.Seafile", "seafile-applet"),
		})
		:once(),
}
