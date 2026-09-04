vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.g.have_nerd_font = true

local path_sep = vim.fn.has 'win32' == 1 and ';' or ':'
local mason_bin = vim.fn.stdpath 'data' .. '/mason/bin'
if vim.uv.fs_stat(mason_bin) and not string.find(vim.env.PATH or '', mason_bin, 1, true) then
  vim.env.PATH = mason_bin .. path_sep .. (vim.env.PATH or '')
end

-- Ensure ftplugin + indent scripts are active (C#, etc. rely on this).
vim.cmd('filetype plugin indent on')

vim.o.number = true
vim.o.relativenumber = true

vim.o.mouse = 'a'
vim.o.showmode = false
vim.opt.shortmess:append 'F'
vim.opt.shortmess:append 'A'

vim.schedule(function()
  if vim.env.SSH_CLIENT or vim.env.SSH_TTY then
    local osc52 = require('vim.ui.clipboard.osc52')

    -- Copy via OSC 52 is async (nvim_ui_send) — instant.
    -- Paste via OSC 52 blocks for 1s+ querying the terminal — unusable.
    -- Return 0 so Neovim falls back to the local register (already synced by unnamedplus on yank).
    vim.g.clipboard = {
      name = 'OSC 52',
      copy = {
        ['+'] = osc52.copy('+'),
        ['*'] = osc52.copy('*'),
      },
      paste = {
        ['+'] = function() return 0 end,
        ['*'] = function() return 0 end,
      },
    }
    vim.o.clipboard = 'unnamedplus'

    -- Explicit cross-system paste (only when you need it — expects ~1s delay for OSC 52 query).
    local osc52_paste_plus = osc52.paste('+')
    vim.keymap.set({ 'n', 'x' }, '<leader>P', function()
      local lines = osc52_paste_plus()
      if lines == 0 then
        vim.notify('No OSC 52 response from terminal', vim.log.levels.WARN)
      else
        vim.api.nvim_paste(lines, true, -1)
      end
    end, { noremap = true, silent = true, desc = 'Paste from system clipboard (OSC 52)' })
  else
    vim.o.clipboard = 'unnamedplus'
  end
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
