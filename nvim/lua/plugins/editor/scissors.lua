return {
  'chrisgrieser/nvim-scissors',
  dependencies = {
    'nvim-telescope/telescope.nvim',
  },
  opts = {
    snippetDir = vim.fn.stdpath 'config' .. '/snippets',
  },
  keys = {
    {
      '<leader>se',
      function()
        require('scissors').editSnippet()
      end,
      desc = 'Snippet: Edit',
    },
    {
      '<leader>sa',
      function()
        require('scissors').addNewSnippet()
      end,
      mode = { 'n', 'x' },
      desc = 'Snippet: Add',
    },
  },
}
