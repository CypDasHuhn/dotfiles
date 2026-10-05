local foldexpr = "v:lua.require'lib.folds'.expr(v:lnum)"
local foldtext = "v:lua.require'lib.folds'.text()"

local function set_fold_highlights()
  vim.api.nvim_set_hl(0, 'FoldRegionName', { fg = '#D4AF37', bold = true })
  vim.api.nvim_set_hl(0, 'FoldRegionLines', { fg = '#5FA8FF' })
end

set_fold_highlights()

vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('folds-highlights', { clear = true }),
  callback = set_fold_highlights,
})

vim.opt.fillchars:append {
  foldopen = '🢗',
  foldclose = '🢖',
  foldsep = ' ',
  foldinner = ' ',
  fold = ' ',
}

vim.opt.foldcolumn = '1'
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = foldexpr
vim.opt.foldtext = foldtext

local function apply(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
    vim.wo[win].foldmethod = 'expr'
    vim.wo[win].foldexpr = foldexpr
    vim.wo[win].foldtext = foldtext
  end
end

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('folds-ftplugin', { clear = true }),
  pattern = '*',
  callback = function(ev)
    vim.schedule(function()
      apply(ev.buf)
    end)
  end,
})

local handled = {}
local pending = {}

local function autofold(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local _, starts = require('lib.region-folds').get_region_levels(bufnr)
  if not starts or next(starts) == nil then
    return
  end

  local seen = handled[bufnr]
  if not seen then
    seen = {}
    handled[bufnr] = seen
  end

  local new = {}
  for lnum in pairs(starts) do
    if not seen[lnum] then
      seen[lnum] = true
      new[lnum] = true
    end
  end

  if next(new) ~= nil then
    require('lib.folds').close_regions(bufnr, new)
  end
end

local function schedule_autofold(bufnr)
  if pending[bufnr] then
    return
  end
  pending[bufnr] = true
  vim.defer_fn(function()
    pending[bufnr] = nil
    autofold(bufnr)
  end, 100)
end

vim.api.nvim_create_autocmd('BufWinEnter', {
  group = vim.api.nvim_create_augroup('folds-window', { clear = true }),
  pattern = '*',
  callback = function(ev)
    apply(ev.buf)
    vim.defer_fn(function()
      autofold(ev.buf)
    end, 0)
  end,
})

vim.api.nvim_create_autocmd({ 'InsertLeave', 'TextChanged' }, {
  group = vim.api.nvim_create_augroup('folds-edit', { clear = true }),
  pattern = '*',
  callback = function(ev)
    schedule_autofold(ev.buf)
  end,
})

vim.api.nvim_create_autocmd('BufDelete', {
  group = vim.api.nvim_create_augroup('fold-cache', { clear = true }),
  callback = function(ev)
    handled[ev.buf] = nil
    pending[ev.buf] = nil
    require('lib.folds').clear(ev.buf)
  end,
})
