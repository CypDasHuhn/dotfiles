local langs = require 'modules.languages'

local path_sep = vim.fn.has 'win32' == 1 and ';' or ':'
local mason_bin = vim.fn.stdpath 'data' .. '/mason/bin'
if vim.uv.fs_stat(mason_bin) and not string.find(vim.env.PATH or '', mason_bin, 1, true) then
  vim.env.PATH = mason_bin .. path_sep .. (vim.env.PATH or '')
end

local function resolve_prettier()
  if vim.fn.executable 'prettier' == 1 then
    return 'prettier'
  end

  if vim.fn.executable 'prettier.cmd' == 1 then
    return 'prettier.cmd'
  end

  local data_path = vim.fn.stdpath 'data'
  local candidates = vim.fn.has 'win32' == 1 and {
    data_path .. '/mason/bin/prettier.cmd',
    data_path .. '/mason/packages/prettier/node_modules/.bin/prettier.cmd',
  } or {
    data_path .. '/mason/bin/prettier',
    data_path .. '/mason/packages/prettier/node_modules/.bin/prettier',
  }

  for _, cmd in ipairs(candidates) do
    if vim.uv.fs_stat(cmd) then
      return cmd
    end
  end

  return 'prettier'
end

return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>f',
      function()
        require('conform').format { async = true, lsp_format = 'fallback' }
      end,
      mode = '',
      desc = '[F]ormat buffer',
    },
  },
  opts = {
    notify_on_error = false,
    format_on_save = function(bufnr)
      -- Disable "format_on_save lsp_fallback" for languages that don't
      -- have a well standardized coding style. You can add additional
      -- languages here or re-enable it for the disabled ones.
      local disable_filetypes = { c = true, cpp = true }
      if disable_filetypes[vim.bo[bufnr].filetype] then
        return nil
      else
        return {
          timeout_ms = 3000,
          lsp_format = 'fallback',
        }
      end
    end,
    formatters = {
      prettier = {
        command = resolve_prettier(),
      },
    },
    formatters_by_ft = vim.tbl_deep_extend('force', {
      lua = { 'stylua' },
    }, langs.formatters),
  },
}
