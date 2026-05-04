local machine = {}
local machine_path = vim.fn.stdpath('config') .. '/.machine.lua'

local ok, machine_cfg = pcall(dofile, machine_path)
if ok and type(machine_cfg) == 'table' then
  machine = machine_cfg
end

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
