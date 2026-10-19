local plugin_dir = vim.fn.stdpath 'data' .. '/lazy/code-intent'

return {
  'CypDasHuhn/code-intent',
  name = 'code-intent',
  enabled = false,
  lazy = false,
  build = './analysis-engine/gradlew -p analysis-engine :server:installDist',
  init = function()
    vim.opt.rtp:append(plugin_dir .. '/nvim-renderer')
  end,
  config = function()
    vim.cmd.runtime 'plugin/cint.lua'
    require('cint').setup {
      auto_render = true,
      scope = 'global',
      server_cmd = {
        plugin_dir .. '/analysis-engine/build/install/cint-server/bin/cint-server',
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
