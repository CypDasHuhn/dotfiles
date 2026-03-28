-- Example dependencies.lua showing all syntax forms
-- Place files named "dependencies.lua" anywhere, they'll be auto-imported

return {
    -- Shortest form: universal command (no verify)
    prettier = "npm install -g prettier",

    -- Using vanilla helper (pacman + winget, with verify)
    -- Third arg is binary name if different from package name
    neovim = vanilla("neovim", "Neovim.Neovim", "nvim"),
    ripgrep = vanilla("ripgrep", "BurntSushi.ripgrep.MSIX", "rg"),
    fd = vanilla("fd", "sharkdp.fd"),

    -- Tool-specific helpers (condition + verify built-in)
    -- Second arg is binary name if different from package name
    eslint = npm_pkg("eslint"),
    black = pipx_pkg("black"),
    stylua = cargo_pkg("stylua"),

    -- OS-level using command helpers
    -- pacman("pkg", "binary") - second arg optional
    wl_clipboard = {
        unix = pacman("wl-clipboard", "wl-copy"),
    },

    -- Distro-level with command helpers
    build_essential = {
        unix = {
            arch = pacman("base-devel", "make"),
            ubuntu = apt("build-essential", "make"),
        },
    },

    -- CPU architecture level
    some_arm_thing = {
        unix = {
            arch = {
                x86_64 = pacman("foo"),
                aarch64 = pacman("foo-arm"),
            },
        },
    },

    -- With explicit condition
    pipx = {
        unix = {
            arch = {
                command = "sudo pacman -S --noconfirm --needed python-pipx",
                condition = which("python"),
                verify = which("pipx"),
            },
        },
    },

    -- Complex: distro + arch + condition + verify
    complex_tool = {
        unix = {
            arch = {
                x86_64 = {
                    command = "yay -S --noconfirm --needed complex-tool",
                    condition = which("yay"),
                    verify = which("complex-tool"),
                },
            },
        },
    },
}
