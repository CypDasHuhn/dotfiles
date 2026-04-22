local h = require("infra.dependencies.helpers")

local has_pkg_resources = "python -c 'import pkg_resources'"
local has_setuptools = "python -c 'import setuptools'"

return {
    ["python-pkg_resources"] = h.dep({
        unix = h.pacman("python-pkg_resources"),
    }):verify(has_pkg_resources):once(),

    ["python-setuptools"] = h.dep({
        unix = h.pacman("python-setuptools"),
    }):verify(has_setuptools):once(),

    nvr = h.dep({
        unix = h.yay("neovim-remote", "nvr"),
    })
        :condition(h.which("nvim") .. " && " .. has_pkg_resources .. " && " .. has_setuptools)
        :verify("nvr --version")
        :once(),
}
