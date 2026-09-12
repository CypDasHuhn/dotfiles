return {
  'kylechui/nvim-surround',
  event = 'VeryLazy',
  init = function()
    vim.g.nvim_surround_no_visual_mappings = true
  end,
  opts = {},
  config = function(_, opts)
    require('nvim-surround').setup(opts)
    vim.keymap.set('x', 'r', '<Plug>(nvim-surround-visual)', { desc = 'Surround selection' })
  end,
}
