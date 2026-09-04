return {
  'stevearc/aerial.nvim',
  event = 'VeryLazy',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  keys = {
    { '<leader>no', '<cmd>AerialToggle!<CR>', desc = 'Toggle symbol outline' },
  },
  opts = {},
}
