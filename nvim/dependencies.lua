local h = require 'infra.dependencies.helpers'

return {
  nvim = h.dep(h.vanilla('nvim', 'Neovim.Neovim')):condition(h.which 'nu'):verify(h.which 'nvim'):once(),
}
