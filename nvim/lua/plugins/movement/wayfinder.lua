return {
  'error311/wayfinder.nvim',
  event = 'VeryLazy',
  keys = {
    {
      '<leader>nw',
      function()
        require('wayfinder').open()
      end,
      desc = '[N]avigate [W]ayfinder',
    },
  },
  opts = {},
}
