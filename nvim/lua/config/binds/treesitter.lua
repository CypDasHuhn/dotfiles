local nav = require 'lib.treesitter-nav'

vim.keymap.set({ 'n', 'x', 'o' }, '<C-l>', function() nav.next_sibling() end, { desc = 'Next sibling' })
vim.keymap.set({ 'n', 'x', 'o' }, '<C-h>', function() nav.rev_sibling() end, { desc = 'Previous sibling' })
vim.keymap.set('n', '<C-k>', function()
  if vim.wo.diff then
    vim.cmd.normal { '[c', bang = true }
  else
    nav.parent()
  end
end, { desc = 'Previous diff change or parent node' })
vim.keymap.set('n', '<C-j>', function()
  if vim.wo.diff then
    vim.cmd.normal { ']c', bang = true }
  else
    nav.first_child()
  end
end, { desc = 'Next diff change or first child node' })
vim.keymap.set({ 'x', 'o' }, '<C-k>', function() nav.parent() end, { desc = 'Parent node' })
vim.keymap.set({ 'x', 'o' }, '<C-j>', function() nav.first_child() end, { desc = 'First child node' })
