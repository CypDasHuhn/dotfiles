local h = require("infra.dependencies.helpers")

return {
    fzf = h.dep({
            windows = "winget install --id=junegunn.fzf -e --silent --accept-package-agreements --accept-source-agreements",
            unix = h.pacman("fzf"),
        })
        :verify(h.which("fzf"))
        :once(),
    ripgrep = h.dep({
            unix = h.pacman("ripgrep", "rg"),
            windows = h.winget("BurntSushi.ripgrep.MSVC", "rg"),
        })
        :once(),
    git = h.dep({
            unix = h.pacman("git"),
            windows = h.winget("Git.Git", "git"),
        })
        :once(),
    make = h.dep({
            unix = h.pacman("make"),
            windows = h.winget("ezwinports.make", "make"),
        })
        :once(),
    unzip = h.dep({
            unix = h.pacman("unzip"),
            windows = h.winget("GnuWin32.UnZip", "unzip"),
        })
        :once(),
    curl = h.dep({
            unix = h.pacman("curl"),
            windows = h.winget("cURL.cURL", "curl"),
        })
        :once(),
    -- bash ships with Git for Windows, so there is no windows branch.
    bash = h.dep({
            unix = h.pacman("bash"),
        })
        :once(),
    npm = h.dep({
            unix = h.pacman("npm"),
            windows = h.winget("OpenJS.NodeJS.LTS", "node"),
        })
        :once(),
    codex = h.dep({
            unix = {
                command = 'npm install -g --prefix "$HOME/.local" @openai/codex',
                condition = h.which("npm"),
                verify = h.which("codex"),
                once = true,
            },
            windows = h.npm_pkg("@openai/codex", "codex"),
        }),
}
