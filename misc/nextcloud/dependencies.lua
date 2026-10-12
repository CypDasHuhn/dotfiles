-- Nextcloud sync client.
--   Unix    -> `nextcloud-client` (provides nextcloudcmd + the desktop client)
--   Windows -> `Nextcloud.NextcloudDesktop` via winget (GUI sync client)
local h = require("infra.dependencies.helpers")

return {
	nextcloud = h.dep({
			unix = h.pacman("nextcloud-client", "nextcloudcmd"),
			windows = h.winget("Nextcloud.NextcloudDesktop", "nextcloud"),
		})
		:once(),
}
