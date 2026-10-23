local plugin_dir = vim.fn.stdpath 'data' .. '/lazy/code-intent'

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
  annotate { vim.fn.line "'<", vim.fn.line "'>" }
end

return {
  'CypDasHuhn/code-intent',
  name = 'code-intent',
  lazy = false,
  build = 'bash -c "cd analysis-engine && ./gradlew :server:installDist"',
  init = function()
    vim.opt.rtp:append(plugin_dir .. '/nvim-renderer')
  end,
  config = function()
    local server = plugin_dir .. '/analysis-engine/build/install/cint-server/bin/cint-server'
    if vim.fn.executable(server) == 0 then
      server = 'cint-server'
    end
    vim.cmd.runtime 'plugin/cint.lua'
    require('cint').setup {
      auto_render = true,
      scope = 'global',
      server_cmd = { server },

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
      desc = 'Cint: accept review group under cursor',
    },
    {
      '<leader>pd',
      '<cmd>CintReviewDeny<cr>',
      desc = 'Cint: deny review group under cursor',
    },
    {
      '<leader>pV',
      '<cmd>CintReviewList<cr>',
      desc = 'Cint: list review groups',
    },
    {
      '<leader>pc',
      '<cmd>CintSuggestCancel<cr>',
      desc = 'Cint: cancel AI suggestion pass',
    },
    {
      '<leader>pI',
      '<cmd>CintRestrictions<cr>',
      desc = 'Cint: inspect AI restrictions',
    },
    {
      '<leader>pA',
      '<cmd>CintAiLog<cr>',
      desc = 'Cint: show AI session log',
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
    {
      '<leader>pi',
      '<cmd>CintUI<cr>',
      desc = 'Cint: remove symbol from rule config field',
    },
  },
}
