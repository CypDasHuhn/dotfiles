return {
  'nvim-treesitter/nvim-treesitter',
  enabled = true,
  essential = true,
  keys = {
    {
      '<C-l>',
      mode = { 'n', 'x', 'o' },
      function()
        require('config.treesitter-nav').next_sibling()
      end,
      desc = 'Next sibling',
    },
    {
      '<C-h>',
      mode = { 'n', 'x', 'o' },
      function()
        require('config.treesitter-nav').prev_sibling()
      end,
      desc = 'Previous sibling',
    },
    {
      '<C-k>',
      mode = { 'n', 'x', 'o' },
      function()
        require('config.treesitter-nav').parent()
      end,
      desc = 'Parent node',
    },
    {
      '<C-j>',
      mode = { 'n', 'x', 'o' },
      function()
        require('config.treesitter-nav').first_child()
      end,
      desc = 'First child',
    },
  },
}
