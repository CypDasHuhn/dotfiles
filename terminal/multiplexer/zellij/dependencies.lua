local h = require("infra.dependencies.helpers")

return {
	zellij = h.dep({
		windows = "winget install --id=arndawg.zellij-windows -e",
		unix = h.pacman("zellij"),
	})
		:condition(h.which("nu"))
		:verify(h.which("zellij"))
		:once(),
}
