local h = require 'infra.dependencies.helpers'

return {
  nvim = h.dep(h.vanilla('nvim', 'Neovim.Neovim')):condition(h.which 'nu'):verify(h.which 'nvim'):once(),
  markdownlint = h.dep({
    unix = h.pacman 'markdownlint-cli2',
    other = h.npm 'markdownlint-cli2',
  })
    :condition(h.which 'nu')
    :verify(h.which 'markdownlint-cli2')
    :once(),
}
