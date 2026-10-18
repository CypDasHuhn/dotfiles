return {
  dir = '~/repos/code-intent/nvim-renderer',
  lazy = false,
  config = function()
    require('cint').setup {
      auto_render = true,
      scope = 'global',
      server_cmd = {
        vim.fn.expand '~/repos/code-intent/analysis-engine/build/install/cint-server/bin/cint-server',
      },

      resolve = {
        precedence = { 'SHOW', 'HIGHLIGHT', 'IGNORE', 'CONCEAL' },
        default = 'SHOW',
      },

      rules = {
        CONCEAL = { conceal = { lines = true } },
        SHOW = false,
        HIGHLIGHT = { highlight = true },
        IGNORE = { ignore = { fg = '#555555' } },
      },

      tags = {
        LOGGING = { meaning = 'CONCEAL', priority = 10 },
        ERROR_HANDLING = { meaning = 'SHOW', bg = '#2d1f1f', priority = 50 },
        UNTAGGED = { meaning = 'SHOW' },
      },

      keymaps = {
        pick = '<leader>pp',
        edit = '<leader>pe',
        shard = '<leader>ps',
      },
    }
  end,
  keys = {
    {
      '<leader>pr',
      '<cmd>CintServerRestart<cr>',
      desc = 'Restart server',
    },
  },
}
