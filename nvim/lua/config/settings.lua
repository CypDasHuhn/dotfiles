vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.g.have_nerd_font = true

-- Ensure ftplugin + indent scripts are active (C#, etc. rely on this).
vim.cmd('filetype plugin indent on')

vim.o.number = true
vim.o.relativenumber = true

vim.o.mouse = 'a'

vim.o.showmode = false

vim.schedule(function()
  vim.o.clipboard = 'unnamedplus'
end)

vim.o.breakindent = true

vim.o.undofile = true

vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.signcolumn = 'yes'

vim.o.updatetime = 250

vim.o.timeoutlen = 300

vim.o.splitright = true
vim.o.splitbelow = true

vim.o.list = true

-- Indentation: keep new lines aligned with the previous line / syntax indent.
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.copyindent = true

vim.opt.expandtab = true
--TODO: Find a way to have this be .editorconfig/prettier dependent.
-- For now not critical since when actually formetting, these will get respected.
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4

-- Continue comments when pressing Enter/o/O.
vim.opt.formatoptions:append { 'r', 'o' }

vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.api.nvim_create_autocmd('BufWritePre', {
  group = vim.api.nvim_create_augroup('retab-on-save', { clear = true }),
  callback = function()
    if vim.bo.expandtab then
      vim.cmd 'retab'
    end
  end,
})

vim.o.inccommand = 'split'

vim.o.cursorline = true

vim.o.scrolloff = 10

vim.o.confirm = true

vim.opt.winborder = 'double'

vim.api.nvim_set_hl(0, 'DiagnosticUnnecessary', { undercurl = true })

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
