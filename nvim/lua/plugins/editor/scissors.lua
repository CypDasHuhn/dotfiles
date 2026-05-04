return {
  'chrisgrieser/nvim-scissors',
  commit = '855ce6b',
  dependencies = {
    'nvim-telescope/telescope.nvim',
  },
  opts = {
    snippetDir = vim.fn.stdpath 'config' .. '/snippets',
  },
  keys = {
    {
      '<leader>re',
      function()
        local ok, scissors = pcall(require, 'scissors')
        if not ok or type(scissors) ~= 'table' then
          scissors = require 'scissors.init'
        end
        scissors.editSnippet()
      end,
      desc = 'Snippet: Edit',
    },
    {
      '<leader>ra',
      function()
        local ok, scissors = pcall(require, 'scissors')
        if not ok or type(scissors) ~= 'table' then
          scissors = require 'scissors.init'
        end
        scissors.addNewSnippet()
      end,
      mode = { 'n', 'x' },
      desc = 'Snippet: Add',
    },
  },
}
