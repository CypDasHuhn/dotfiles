return {
  'error311/wayfinder.nvim',
  event = 'VeryLazy',
  keys = {
    {
      '<leader>gw',
      function()
        require('wayfinder').open()
      end,
      desc = '[G]o [W]ayfinder',
    },
  },
  opts = {},
}
