return {
  'neovim/nvim-lspconfig',
  dependencies = {
    {
      'hasansujon786/nvim-navbuddy',
      dependencies = {
        'SmiteshP/nvim-navic',
        'MunifTanjim/nui.nvim',
      },
      opts = {
        window = {
          border = 'double',
          size = '90%',
          position = '50%',
          sections = {
            left = { size = '20%' },
            mid = { size = '40%' },
            right = { preview = 'leaf' },
          },
        },
        lsp = { auto_attach = true },
      },
    },
  },
}
