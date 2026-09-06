vim.keymap.set('n', '<leader>glr', '<cmd>lsp restart<cr>', { desc = 'Restart LSP client(s)' })
vim.keymap.set('n', '<leader>glg', function()
    vim.cmd('tabnew ' .. vim.lsp.log.get_filename())
end, { desc = 'Open LSP log' })
vim.keymap.set('n', '<leader>gli', '<cmd>checkhealth vim.lsp<cr>', { desc = 'LSP info' })

vim.keymap.set('n', '<leader>xq', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set('n', '<leader>td', function()
    local new_config = not vim.diagnostic.config().virtual_lines
    vim.diagnostic.config { virtual_lines = new_config, virtual_text = not new_config }
end, { desc = '[T]oggle [D]iagnostic lines' })

vim.keymap.set('n', '<leader>tD', function()
    vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = '[T]oggle [D]iagnostics' })
