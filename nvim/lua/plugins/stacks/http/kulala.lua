return {
  'mistweaverco/kulala.nvim',
  init = function()
    vim.filetype.add {
      extension = {
        http = 'http',
        rest = 'rest',
      },
    }
  end,
  event = { 'SessionLoadPost', 'VimLeavePre' },
  ft = { 'http', 'rest' },
  config = function()
    require('kulala').setup {
      global_keymaps = true,
    }
  end,
}
