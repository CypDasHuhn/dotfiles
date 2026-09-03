local h = require("infra.dependencies.helpers")

return {
    fzf = h.dep({
            windows = "winget install --id=junegunn.fzf -e",
            unix = h.pacman("fzf"),
        })
        :verify(h.which("fzf"))
        :once(),

    claude = h.dep({
            unix = "curl -fsSL https://claude.ai/install.sh | bash",
            windows = "irm https://claude.ai/install.ps1 | iex",
        })
        :condition(h.which("nu"))
        :verify(h.which("claude"))
        :once(),
}
