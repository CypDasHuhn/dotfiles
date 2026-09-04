return {
  'folke/noice.nvim',
  event = 'VeryLazy',
  dependencies = {
    'MunifTanjim/nui.nvim',
    'rcarriga/nvim-notify',
  },
  keys = {
    { '<leader>gm', '<cmd>Noice history<cr>', desc = 'Show [M]essage history' },
  },
  opts = {
    cmdline = { enabled = false },
    messages = { enabled = true },
    notify = { enabled = true },
    lsp = {
      progress = { enabled = false },
      hover = { enabled = false },
      signature = { enabled = false },
    },
    popupmenu = { enabled = false },
  },
}
