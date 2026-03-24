local h = require("dependencies.helpers")
--TODO: fzf

return {
	claude = h.dep({
		unix = "curl -fsSL https://claude.ai/install.sh | bash",
		windows = "irm https://claude.ai/install.ps1 | iex",
	})
		:condition(h.which("nu"))
		:verify(h.which("claude"))
		:once(),
}
