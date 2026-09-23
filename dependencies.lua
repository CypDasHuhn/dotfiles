local h = require("infra.dependencies.helpers")

return {
    fzf = h.dep({
            windows = "winget install --id=junegunn.fzf -e",
            unix = h.pacman("fzf"),
        })
        :verify(h.which("fzf"))
        :once(),
    npm = h.dep({
        unix = h.pacman("npm"),
    })
}
