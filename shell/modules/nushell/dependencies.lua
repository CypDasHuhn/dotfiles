local h = require("infra.dependencies.helpers")

return {
    nushell = h.dep({
            unix = h.pacman("nushell")
        })
        :verify(h.which("nu"))
        :once(),
}
