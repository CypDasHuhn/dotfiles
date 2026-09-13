return {
  'folke/todo-comments.nvim',
  event = 'VeryLazy',
  dependencies = { 'nvim-lua/plenary.nvim' },
  opts = { signs = false },
  config = function(_, opts)
    require('todo-comments').setup(opts)

    --region Pickers
    vim.keymap.set('n', '<leader>st', '<cmd>TodoTelescope<cr>', { desc = '[S]earch [T]odos' })
    vim.keymap.set('n', '<leader>xt', '<cmd>TodoTrouble<cr>', { desc = '[T]odos (Trouble)' })
    vim.keymap.set('n', '<leader>xT', '<cmd>TodoQuickFix<cr>', { desc = '[T]odos (QuickFix)' })
    --endregion
  end,
}
