return {
  dir = '~/repos/semantic-code-painter/nvim-renderer',
  config = function()
    require('semantic_code_painter').setup {
      auto_render = true,

      resolve = {
        precedence = { 'SHOW', 'HIGHLIGHT', 'IGNORE', 'CONCEAL' },
        default = 'SHOW',
      },

      rules = {
        CONCEAL = { conceal = { lines = true } },
        SHOW = { highlight = true },
        HIGHLIGHT = { highlight = true },
        IGNORE = { ignore = { fg = '#555555' } },
      },

      tags = {
        Logging = { meaning = 'CONCEAL', bg = '#1f2d1f', priority = 10 },
        ErrorHandling = { meaning = 'SHOW', bg = '#2d1f1f', priority = 50 },
        UNTAGGED = { meaning = 'SHOW' },
      },

      keymaps = {
        pick = '<leader>pp',
        edit = '<leader>pe',
      },
    }
  end,
}
