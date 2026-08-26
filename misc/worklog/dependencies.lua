local h = require("infra.dependencies.helpers")

return {
	git_standup = h.dep({
		unix = {
			command = 'npm install -g --prefix "$HOME/.local" git-standup',
			condition = h.which("npm"),
			verify = h.which("git-standup"),
			once = true,
		},
		windows = h.npm_pkg("git-standup", "git-standup"),
	}),
}
