local machine = require 'config.machine'
local vdir_machine = machine.vdir or {}

return {
  dir = vdir_machine.dir or '~/repos/vdir.nvim',
  dependencies = {
    'nvim-neo-tree/neo-tree.nvim',
    'MunifTanjim/nui.nvim',
  },
  enabled = vdir_machine.enabled == true,
  cmd = 'Vdir',
  keys = {
    { '<leader>q', '<cmd>Vdir<cr>', desc = 'Toggle Vdir' },
  },
}
