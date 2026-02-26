vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- region Disable Arrows
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')
-- endregion

-- region Move Focus
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })
-- endregion

-- region Line Swap
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
-- endregion

vim.keymap.set('n', 'Q', ':q<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<A-Q>', ':qa<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<A-w>', ':w<CR>', { noremap = true, silent = true })

vim.keymap.set('n', 'q', '<nop>')
vim.keymap.set('n', '<leader>m', 'q')

-- Bind $ to g_. This is since i dont like $ including new line char.
vim.keymap.set({ 'n', 'v', 'o' }, '$', 'g_', { noremap = true })
-- When pasting, makes it so that whatever you pasted wont get saved into your clipboard
vim.keymap.set('v', 'p', '"_dP', { noremap = true })
-- region LSP Actions
vim.keymap.set('n', 'grI', function()
  vim.lsp.buf.code_action {
    filter = function(action)
      return action.kind and (action.kind:match 'quickfix' or action.kind:match 'source.addMissingImports' or action.kind:match 'source.organizeImports')
    end,
    apply = true,
  }
end, { desc = '[I]mport actions' })
-- endregion

vim.keymap.set('n', '<leader>sf', function()
  vim.ui.input({ prompt = 'Grep in directory: ', completion = 'dir' }, function(dir)
    if dir then
      require('telescope.builtin').live_grep { search_dirs = { dir } }
    end
  end)
end)
