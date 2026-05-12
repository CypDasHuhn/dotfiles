return {
  'folke/flash.nvim',
  essential = true,
  enabled = true,
  event = 'VeryLazy',
  ---@type Flash.Config
  opts = {},
  keys = {
    {
      'o',
      mode = { 'n', 'x', 'o' },
      function()
        require('flash').jump()
      end,
      desc = 'Flash',
    },
    {
      'O',
      mode = { 'n', 'x', 'o' },
      function()
        require('flash').treesitter()
      end,
      desc = 'Flash Treesitter',
    },
    {
      '<c-o>',
      mode = { 'c' },
      function()
        require('flash').toggle()
      end,
      desc = 'Toggle Flash Search',
    },
  },
}
