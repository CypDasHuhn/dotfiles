vim.keymap.set('n', '<leader>glr', ':LspRestart<cr>')
vim.keymap.set('n', '<leader>glg', ':LspLog<cr>')
vim.keymap.set('n', '<leader>gli', ':LspInfo<cr>')

vim.keymap.set('n', '<leader>xq', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set('n', '<leader>td', function()
    local new_config = not vim.diagnostic.config().virtual_lines
    vim.diagnostic.config { virtual_lines = new_config, virtual_text = not new_config }
end, { desc = '[T]oggle [D]iagnostic lines' })

vim.keymap.set('n', '<leader>tD', function()
    vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = '[T]oggle [D]iagnostics' })
