local region_fold_cache = {}

local function compute_region_folds(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local fold_type = {}
  local stack = {}
  local starts = {}

  for i, line in ipairs(lines) do
    if line:match '%f[%w]region%f[%W]' then
      table.insert(stack, i)
    elseif line:match '%f[%w]endregion%f[%W]' then
      if #stack > 0 then
        local start_line = table.remove(stack)
        fold_type[start_line] = 'start'
        fold_type[i] = 'end'
        table.insert(starts, start_line)
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

  region_fold_cache[bufnr] = {
    levels = levels,
    starts = starts,
  }
end

local function get_region_folds(bufnr)
  if not region_fold_cache[bufnr] then
    compute_region_folds(bufnr)
  end

  return region_fold_cache[bufnr]
end

function _G.RegionFoldExpr()
  local bufnr = vim.api.nvim_get_current_buf()
  local region_folds = get_region_folds(bufnr)
  local value = region_folds.levels[vim.v.lnum] or '='

  if value == '=' then
    return vim.treesitter.foldexpr()
  end

  return value
end

local function for_each_region_fold(bufnr, callback)
  local region_folds = get_region_folds(bufnr)
  for _, lnum in ipairs(region_folds.starts) do
    callback(lnum)
  end
end

local function close_region_folds(bufnr)
  for_each_region_fold(bufnr, function(lnum)
    pcall(vim.cmd, ('silent keepjumps %dfoldclose'):format(lnum))
  end)
end

local function open_region_folds(bufnr)
  for_each_region_fold(bufnr, function(lnum)
    pcall(vim.cmd, ('silent keepjumps %dfoldopen!'):format(lnum))
  end)
end

vim.api.nvim_create_user_command('RegionFoldsCloseAll', function()
  close_region_folds(vim.api.nvim_get_current_buf())
end, {})

vim.api.nvim_create_user_command('RegionFoldsOpenAll', function()
  open_region_folds(vim.api.nvim_get_current_buf())
end, {})

vim.api.nvim_create_autocmd({ 'BufEnter', 'BufReadPost' }, {
  group = vim.api.nvim_create_augroup('region-fold-cache', { clear = true }),
  callback = function(ev)
    vim.api.nvim_buf_attach(ev.buf, false, {
      on_lines = function(_, b)
        region_fold_cache[b] = nil
      end,
    })
  end,
})

vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
  group = vim.api.nvim_create_augroup('region-fold-invalidate', { clear = true }),
  callback = function(ev)
    region_fold_cache[ev.buf] = nil
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('region-fold-setup', { clear = true }),
  callback = function()
    vim.wo.foldmethod = 'expr'
    vim.wo.foldexpr = 'v:lua.RegionFoldExpr()'
    vim.o.foldlevelstart = 99
  end,
})

vim.keymap.set('n', '<leader>zc', '<cmd>RegionFoldsCloseAll<CR>', { desc = 'Region Folds: Close All' })
vim.keymap.set('n', '<leader>zo', '<cmd>RegionFoldsOpenAll<CR>', { desc = 'Region Folds: Open All' })
