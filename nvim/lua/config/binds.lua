vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

vim.keymap.set('n', '<leader>xq', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' }) -- region Disable Arrows
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')
-- endregion region Line Swap
vim.keymap.set('n', '<A-j>', '<cmd>m .+1<CR>==', { desc = 'Move line down' })
vim.keymap.set('n', '<A-k>', '<cmd>m .-2<CR>==', { desc = 'Move line up' })
vim.keymap.set('v', '<A-j>', ":m '>+1<CR>gv=gv", { desc = 'Move selection down' })
vim.keymap.set('v', '<A-k>', ":m '<-2<CR>gv=gv", { desc = 'Move selection up' })
-- endregion

-- region Case dependent Motion
vim.keymap.set({ 'n', 'v', 'o' }, 's', function()
  vim.fn.search('[^a-zA-Z]\\zs[a-zA-Z]\\|[A-Z]', 'W')
end, { desc = 'Subword forward', silent = true })
vim.keymap.set({ 'n', 'v', 'o' }, 'S', function()
  vim.fn.search('[^a-zA-Z]\\zs[a-zA-Z]\\|[A-Z]', 'bW')
end, { desc = 'Subword backward', silent = true })
-- endregion

vim.keymap.set('n', '<CR>', 'i<CR><Esc>', { desc = 'Split line at cursor' })

-- region Diagnostics
vim.keymap.set('n', '<leader>td', function()
  local new_config = not vim.diagnostic.config().virtual_lines
  vim.diagnostic.config { virtual_lines = new_config, virtual_text = not new_config }
end, { desc = '[T]oggle [D]iagnostic lines' })

vim.keymap.set('n', '<leader>tD', function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = '[T]oggle [D]iagnostics' })
-- endregion

vim.keymap.set('n', 'Q', ':q<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<A-Q>', ':qa<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<A-w>', ':w<CR>', { noremap = true, silent = true })

vim.keymap.set('n', 'q', '<nop>')
vim.keymap.set('n', '<leader>m', 'q')

-- Bind $ to g_. This is since i dont like $ including new line char.
vim.keymap.set({ 'n', 'v', 'o' }, '$', 'g_', { noremap = true })

-- region Clipboard-safe deletes/paste
-- Keep `x` from updating unnamed/clipboard register.
vim.keymap.set({ 'n', 'x' }, 'x', '"_x', { noremap = true, silent = true })
-- Preserve old `x` behavior on `X` (delete + yank into unnamed register).
vim.keymap.set({ 'n', 'x' }, 'X', 'x', { noremap = true, silent = true })

-- In visual mode, paste over selection without yanking replaced text.
vim.keymap.set('x', 'p', '"_dP', { noremap = true, silent = true })
vim.keymap.set('x', 'P', '"_dP', { noremap = true, silent = true })
-- endregion

vim.keymap.set('n', 'gg', 'gg0')

-- nuke g* except gg and gr*
for _, key in ipairs { 'e', 'f', 'i', 'n', 'N', 't', 'T', 'u', 'U', 'v', 'w', 'O', 'W', '%', ',', ';', '~', '`', "'", 'cc' } do
  vim.keymap.set('n', 'g' .. key, '<nop>')
end
-- gcc → rcc: comment toggle
vim.keymap.set('n', '<leader>rc', function()
  return require('vim._comment').operator()
end, { expr = true, desc = 'Comment toggle' })
vim.keymap.set('x', '<leader>rc', function()
  return require('vim._comment').operator(vim.fn.visualmode())
end, { expr = true, desc = 'Comment toggle' })

vim.keymap.set('n', '<leader>i', ':Lazy<CR>', { noremap = true })

vim.keymap.set({ 'n', 'v', 'o' }, '<leader>ts', '<cmd>set spell!<cr>', { desc = 'Toggle spell' })

vim.keymap.set('n', '<leader>wn', '<cmd>noautocmd w<cr>')

vim.keymap.set('n', '<leader>glr', ':LspRestart<cr>')
vim.keymap.set('n', '<leader>glg', ':LspLog<cr>')
vim.keymap.set('n', '<leader>gli', ':LspInfo<cr>')

vim.keymap.set('v', '<leader>rn', function()
  require('lib.normalize-selection').normalize_selection()
end, { desc = 'Normalize selection' })
