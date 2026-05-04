return {
  'antosha417/nvim-lsp-file-operations',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-neo-tree/neo-tree.nvim',
  },
  config = function()
    if vim.lsp.get_active_clients then
      vim.lsp.get_active_clients = vim.lsp.get_clients
    end
    require('lsp-file-operations').setup()
  end,
}
