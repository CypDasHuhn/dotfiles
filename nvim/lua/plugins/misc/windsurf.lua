local machine = require 'config.machine'
local windsurf_machine = machine.windsurf or {}

return {
  'Exafunction/windsurf.nvim',
  enabled = windsurf_machine.enabled ~= false,
  event = 'VeryLazy',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  config = function()
    -- Windows guard
    local git_usr_bin = 'C:/Program Files/Git/usr/bin'
    if vim.fn.executable 'gzip' == 0 and vim.fn.executable(git_usr_bin .. '/gzip.exe') == 1 then
      vim.env.PATH = git_usr_bin .. ';' .. vim.env.PATH
    end

    vim.keymap.set('n', '<leader>tc', '<cmd>Codeium Toggle', { buffer = true })

    require('codeium').setup {
      -- Using blink.cmp integration, not nvim-cmp.
      enable_cmp_source = false,
      virtual_text = {
        enabled = true,
        manual = false,
        map_keys = true,
        accept_fallback = false,
        key_bindings = {
          accept = '<C-i>',
          next = '<C-,>',
          prev = '<C-.>',
          clear = '<C-x>',
          accept_word = false,
          accept_line = false,
        },
      },
    }
  end,
}
