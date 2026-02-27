-- region Modules
require '.config.settings'
require '.config.binds'
-- endregion

-- region Filetypes
vim.filetype.add {
  pattern = {
    ['.*/hypr/.*%.conf'] = 'hyprlang',
    ['.*/hyprland/.*%.conf'] = 'hyprlang',
  },
}
-- endregion

-- region Yank
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})
-- endregion

-- region Folding
local _region_fold_cache = {}

local function _compute_region_folds(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local fold_type = {}
  local stack = {}

  for i, line in ipairs(lines) do
    if line:match '%f[%w]region%f[%W]' then
      table.insert(stack, i)
    elseif line:match '%f[%w]endregion%f[%W]' then
      if #stack > 0 then
        local s = table.remove(stack)
        fold_type[s] = 'start'
        fold_type[i] = 'end'
      end
    end
  end

  local levels = {}
  local level = 0
  for i = 1, #lines do
    if fold_type[i] == 'start' then
      level = level + 1
      levels[i] = '>' .. level
    elseif fold_type[i] == 'end' then
      levels[i] = '<' .. level
      level = level - 1
    else
      levels[i] = '='
    end
  end

  _region_fold_cache[bufnr] = levels
end

function _G.RegionFoldExpr()
  local bufnr = vim.api.nvim_get_current_buf()
  if not _region_fold_cache[bufnr] then
    _compute_region_folds(bufnr)
  end
  return _region_fold_cache[bufnr][vim.v.lnum] or '='
end

vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
  callback = function(ev)
    _region_fold_cache[ev.buf] = nil
  end,
})

-- FileType runs after ftplugins, so this overrides per-ft foldexpr overrides (e.g. lua.lua sets treesitter foldexpr)
vim.api.nvim_create_autocmd('FileType', {
  callback = function()
    vim.wo.foldmethod = 'expr'
    vim.wo.foldexpr = 'v:lua.RegionFoldExpr()'
  end,
})
-- endregion

-- region Lazy
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end
-- endregion

---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

require('lazy').setup({
  'NMAC427/guess-indent.nvim',
  { 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },
  { import = 'plugins' },
}, {
  -- region icons
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
  -- endregion
})
