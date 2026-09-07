local h = require("infra.dependencies.helpers")

return {
	watchexec = h.dep({
		unix = h.pacman("watchexec"),
	})
		:once(),
}
