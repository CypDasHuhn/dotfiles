local nav = require 'lib.treesitter-nav'

return {
  'nvim-treesitter/nvim-treesitter',
  enabled = true,
  essential = true,
  keys = {
    {
      '<C-l>',
      mode = { 'n', 'x', 'o' },
      function()
        nav.next_sibling()
      end,
      desc = 'Next sibling',
    },
    {
      '<C-h>',
      mode = { 'n', 'x', 'o' },
      function()
        nav.rev_sibling()
      end,
      desc = 'Previous sibling',
    },
    {
      '<C-k>',
      mode = { 'n', 'x', 'o' },
      function()
        nav.parent()
      end,
      desc = 'Parent node',
    },
    {
      '<C-j>',
      mode = { 'n', 'x', 'o' },
      function()
        nav.first_child()
      end,
      desc = 'First child',
    },
  },
}
