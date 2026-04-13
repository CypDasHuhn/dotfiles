local h = require 'infra.dependencies.helpers'

-- ripgrep, lazygit

return {
    nvim = h.dep(h.vanilla('nvim', 'Neovim.Neovim')):condition(h.which 'nu'):verify(h.which 'nvim'):once(),
    markdownlint = h.dep({
        unix = h.pacman 'markdownlint-cli2',
        windows = h.npm_pkg 'markdownlint-cli2',
    }):once(),
}
