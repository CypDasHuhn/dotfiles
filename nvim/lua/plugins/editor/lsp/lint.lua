return {

  { -- Linting
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'
      local langs = require '.config.lang-packs.init'
      local all_linters = vim.tbl_deep_extend('force', {
        -- TODO: move to config
        markdown = { 'markdownlint' },
      }, langs.linters)
      local available_linters = {}
      for ft, linters in pairs(all_linters) do
        local available = vim.tbl_filter(function(linter)
          local cfg = lint.linters[linter]
          local cmd = type(cfg) == 'table' and cfg.cmd or linter
          return vim.fn.executable(cmd) == 1
        end, linters)
        if #available > 0 then
          available_linters[ft] = available
        end
      end
      lint.linters_by_ft = available_linters

      -- TODO: move to config
      lint.linters.markdownlint.args = {
        '--disable', 'MD013',
      }

      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          if vim.bo.modifiable and vim.bo.buftype == '' then
            lint.try_lint()
          end
        end,
      })
    end,
  },
}
