local h = require("infra.dependencies.helpers")

return {
    tmux = h.dep({
            unix = h.pacman("tmux"),
        })
        :verify(h.which("tmux"))
        :once(),
}
