local h = require 'infra.dependencies.helpers'

-- ripgrep

return {
    nvim = h.dep(h.vanilla('nvim', 'Neovim.Neovim')):condition(h.which 'nu'):verify(h.which 'nvim'):once(),
    markdownlint = h.dep({
        unix = h.pacman 'markdownlint-cli2',
        windows = h.npm_pkg 'markdownlint-cli2',
    }):once(),
    treesitter = h.dep(h.npm_pkg('tree-sitter-cli'))
    -- LaTeX -> unicode converter for render-markdown.nvim (opts.latex.converter = latex2text)
}
