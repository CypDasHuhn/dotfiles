vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

vim.keymap.set('n', '<A-j>', '<cmd>m .+1<CR>==', { desc = 'Move line down' })
vim.keymap.set('n', '<A-k>', '<cmd>m .-2<CR>==', { desc = 'Move line up' })
vim.keymap.set('v', '<A-j>', ":m '>+1<CR>gv=gv", { desc = 'Move selection down' })
vim.keymap.set('v', '<A-k>', ":m '<-2<CR>gv=gv", { desc = 'Move selection up' })

vim.keymap.set({ 'n', 'v', 'o' }, 's', function()
  vim.fn.search('[^a-zA-Z]\\zs[a-zA-Z]\\|[A-Z]', 'W')
end, { desc = 'Subword forward', silent = true })
vim.keymap.set({ 'n', 'v', 'o' }, 'S', function()
  vim.fn.search('[^a-zA-Z]\\zs[a-zA-Z]\\|[A-Z]', 'bW')
end, { desc = 'Subword backward', silent = true })

vim.keymap.set('n', '<CR>', 'i<CR><Esc>', { desc = 'Split line at cursor' })
vim.keymap.set('n', 'Q', ':q<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<A-Q>', ':qa<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<A-w>', ':w<CR>', { noremap = true, silent = true })
vim.keymap.set('n', 'q', '<nop>')
vim.keymap.set('n', '<leader>m', 'q')
vim.keymap.set({ 'n', 'v', 'o' }, '$', 'g_', { noremap = true })

vim.keymap.set({ 'n', 'x' }, 'x', '"_x', { noremap = true, silent = true })
vim.keymap.set({ 'n', 'x' }, 'X', 'x', { noremap = true, silent = true })
vim.keymap.set('x', 'p', '"_dP', { noremap = true, silent = true })
vim.keymap.set('x', 'P', '"_dP', { noremap = true, silent = true })
vim.keymap.set('n', 'gg', 'gg0')

for _, key in ipairs { 'e', 'f', 'i', 'n', 'N', 'u', 'U', 'v', 'w', 'O', 'W', '%', ',', ';', '~', '`', "'", 'cc' } do
  vim.keymap.set('n', 'g' .. key, '<nop>')
end

vim.keymap.set('n', '<leader>rc', function()
  return require('vim._comment').operator()
end, { expr = true, desc = 'Comment toggle' })
vim.keymap.set('x', '<leader>rc', function()
  return require('vim._comment').operator(vim.fn.visualmode())
end, { expr = true, desc = 'Comment toggle' })

vim.keymap.set('n', '<leader>i', ':Lazy<CR>', { noremap = true })
vim.keymap.set({ 'n', 'v', 'o' }, '<leader>ts', '<cmd>set spell!<cr>', { desc = 'Toggle spell' })
vim.keymap.set('n', '<leader>wn', '<cmd>noautocmd w<cr>')
vim.keymap.set('v', '<leader>rn', function()
  require('lib.normalize-selection').normalize_selection()
end, { desc = 'Normalize selection' })

require('lib.surround').register_keymaps()
