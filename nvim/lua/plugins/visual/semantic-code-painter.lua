return {
  dir = '~/repos/semantic-code-painter/nvim-renderer',
  config = function()
    require('semantic_code_painter').setup {
      auto_render = true,

      meanings = {
        CONCEAL = { conceal = { lines = true } },
        SHOW = { highlight = true },
        HIGHLIGHT = { highlight = true },
        IGNORE = { ignore = { fg = '#555555' } },
      },

      tags = {
        Logging = { bg = '#1f2d1f', priority = 10, conceal = { lines = true } },
        ErrorHandling = { bg = '#2d1f1f', priority = 50, highlight = true },
      },
    }
  end,
}
