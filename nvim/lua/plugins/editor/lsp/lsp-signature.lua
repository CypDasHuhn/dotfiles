return {
  'ray-x/lsp_signature.nvim',
  event = 'VeryLazy',
  config = function()
    require('lsp_signature').setup {
      handler_opts = { border = 'rounded' },
      hint_prefix = '',
    }
  end,
}
