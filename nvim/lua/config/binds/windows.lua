vim.keymap.set('n', '<S-l>', '<C-w>l', { desc = 'Window right' })
vim.keymap.set('n', '<S-h>', '<C-w>h', { desc = 'Window left' })
vim.keymap.set('n', '<S-j>', '<C-w>j', { desc = 'Window down' })
vim.keymap.set('n', '<S-k>', '<C-w>k', { desc = 'Window up' })

vim.keymap.set('n', '<leader>gtj', '<cmd>tabnext<cr>', { desc = 'Next tabpage' })
vim.keymap.set('n', '<leader>gtp', '<cmd>tabprevious<cr>', { desc = 'Previous tabpage' })
for i = 1, 9 do
    vim.keymap.set('n', '<leader>gt' .. i, '<cmd>tabnext ' .. i .. '<cr>', { desc = 'Go to tabpage ' .. i })
end
