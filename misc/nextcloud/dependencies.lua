-- Nextcloud sync client.
--   Unix    -> `nextcloud-client` (provides the desktop client + nextcloudcmd)
--   Windows -> `Nextcloud.NextcloudDesktop` via winget (desktop client)
local h = require("infra.dependencies.helpers")

return {
	nextcloud = h.dep({
			unix = h.pacman("nextcloud-client", "nextcloudcmd"),
			windows = h.winget("Nextcloud.NextcloudDesktop", "nextcloud"),
		})
		:once(),
}
