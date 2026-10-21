local repo = vim.env.repos .. '/code-intent'

local function annotate(range)
  vim.ui.input({ prompt = 'Cint intent: ' }, function(value)
    value = vim.trim(value or '')
    if value == '' then
      return
    end
    vim.schedule(function()
      local args = vim.split(value, '%s+', { trimempty = true })
      local command = { cmd = 'CintAnnotate', args = args }
      if range then
        command.range = range
      end
      local ok, err = pcall(vim.api.nvim_cmd, command, {})
      if not ok then
        vim.notify('cint: ' .. tostring(err), vim.log.levels.WARN)
      end
    end)
  end)
end

local function annotate_visual()
  annotate({ vim.fn.line("'<"), vim.fn.line("'>") })
end

return {
  'CypDasHuhn/code-intent',
  name = 'code-intent',
  dev = true,
  dir = repo .. '/nvim-renderer',
  lazy = false,
  build = 'bash -c "cd .. && ./analysis-engine/gradlew -p analysis-engine :server:installDist"',
  config = function()
    vim.cmd.runtime 'plugin/cint.lua'
    require('cint').setup {
      auto_render = true,
      scope = 'global',
      server_cmd = {
        repo .. '/analysis-engine/build/install/cint-server/bin/cint-server',
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
      desc = 'Cint: restart server',
    },
    {
      '<leader>pu',
      '<cmd>CintSuggest<cr>',
      desc = 'Cint: suggest AI candidates',
    },
    {
      '<leader>pv',
      '<cmd>CintReview<cr>',
      desc = 'Cint: toggle candidate review',
    },
    {
      '<leader>pl',
      '<cmd>CintIntentLabels<cr>',
      desc = 'Cint: toggle annotation intent labels',
    },
    {
      '<leader>pm',
      '<cmd>CintStripes<cr>',
      desc = 'Cint: toggle mixed-intent stripes',
    },
    {
      '<leader>pa',
      '<cmd>CintReviewAccept<cr>',
      desc = 'Cint: accept candidate under cursor',
    },
    {
      '<leader>pd',
      '<cmd>CintReviewDeny<cr>',
      desc = 'Cint: deny candidate group under cursor',
    },
    {
      '<leader>pn',
      function()
        annotate(nil)
      end,
      desc = 'Cint: annotate symbol under cursor',
    },
    {
      '<leader>pn',
      annotate_visual,
      mode = 'v',
      desc = 'Cint: annotate selected range',
    },
    {
      '<leader>pN',
      '<cmd>CintUnannotate<cr>',
      desc = 'Cint: remove annotation at cursor/range',
    },
    {
      '<leader>pca',
      '<cmd>CintConfigAdd<cr>',
      desc = 'Cint: add symbol to rule config field',
    },
    {
      '<leader>pcr',
      '<cmd>CintConfigRemove<cr>',
      desc = 'Cint: remove symbol from rule config field',
    },
  },
}
