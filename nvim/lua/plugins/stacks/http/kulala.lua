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
    -- kulala's grammar fetcher wedges on a checkout without an `origin`
    -- remote; repair it first. See lib/kulala-grammar.lua.
    require('lib.kulala-grammar').repair()
    require('kulala').setup {
      global_keymaps = true,
      treesitter = {
        enable = true,
      },
    }
  end,
}
