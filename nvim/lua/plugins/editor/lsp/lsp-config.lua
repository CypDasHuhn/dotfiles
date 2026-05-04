return {
  'neovim/nvim-lspconfig',
  event = 'VeryLazy',
  config = function(_, opts)
    require('lib.lsp_setup').setup(opts)
  end,
}
