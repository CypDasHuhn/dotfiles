local h = require("dependencies.helpers")

local claude = {
	unix = "command -v claude >/dev/null 2>&1 || curl -fsSL https://claude.ai/install.sh | bash",
	windows = "if (-not (Get-Command claude -ErrorAction SilentlyContinue)) { irm https://claude.ai/install.ps1 | iex }",
}
claude = h.conditionAll(claude, h.which("nu"))
claude = h.verifyAll(claude, h.which("claude"))

--TODO: fzf

return {
	claude = claude,
}
