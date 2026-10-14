vim.keymap.set('n', 'zI', function()
  vim.wo.foldenable = true
  require('lib.folds').close_regions(vim.api.nvim_get_current_buf())
end, { desc = 'Fold all regions' })
