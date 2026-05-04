return {
  'OXY2DEV/markview.nvim',
  enabled = false,
  lazy = false, -- internal lazy loading

  -- Completion for `blink.cmp`
  dependencies = { 'saghen/blink.cmp' },
  config = function()
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'markdown',
      callback = function()
        vim.keymap.set('n', '<leader>ls', '<cmd>Markview splitToggle<CR>', { buffer = true })
      end,
    })
  end,
}
