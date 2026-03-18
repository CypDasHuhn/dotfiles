local region_fold_cache = {}
local region_fold_initialized = {}

local comment_starters = { '//', '#', '--', '*', '<!--', '/*', ';', '%' }

local function line_matches_keyword(line, keyword, starters)
  for _, starter in ipairs(starters) do
    if line:match('^%s*' .. vim.pesc(starter) .. '%s*' .. keyword .. '%f[%W]') then
      return true
    end
  end
  return false
end

local function compute_region_folds(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local levels = {}
  local stack = {}
  local starts = {}

  for i, line in ipairs(lines) do
    if line_matches_keyword(line, 'region', comment_starters) then
      table.insert(stack, i)
      levels[i] = { kind = 'start', depth = #stack }
    elseif line_matches_keyword(line, 'endregion', comment_starters) then
      if #stack > 0 then
        table.insert(starts, stack[#stack])
        levels[i] = { kind = 'end', depth = #stack }
        table.remove(stack)
      end
    elseif #stack > 0 then
      levels[i] = { kind = 'inside', depth = #stack }
    end
  end

  region_fold_cache[bufnr] = { levels = levels, starts = starts }
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
  local info = region_folds.levels[vim.v.lnum]

  if not info then
    return vim.treesitter.foldexpr()
  end

  if info.kind == 'start' then
    return '>' .. info.depth
  elseif info.kind == 'end' then
    return '<' .. info.depth
  else
    -- Inside a region: combine region depth with treesitter level so nested
    -- treesitter folds still work inside regions.
    local ts = vim.treesitter.foldexpr()
    local ts_num = type(ts) == 'number' and ts or (tonumber(tostring(ts):match '%d+') or 0)
    return info.depth + ts_num
  end
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

vim.opt.fillchars:append {
  foldopen = '▾',
  foldclose = '▸',
  foldsep = ' ',
  fold = ' ',
}

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('region-fold-setup', { clear = true }),
  callback = function()
    vim.wo.foldmethod = 'expr'
    vim.wo.foldexpr = 'v:lua.RegionFoldExpr()'
    vim.wo.foldcolumn = '1'
    vim.o.foldlevelstart = 99
  end,
})

vim.api.nvim_create_autocmd('BufWinEnter', {
  group = vim.api.nvim_create_augroup('region-fold-autoclose', { clear = true }),
  callback = function(ev)
    if region_fold_initialized[ev.buf] then
      return
    end
    region_fold_initialized[ev.buf] = true
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(ev.buf) then
        close_region_folds(ev.buf)
      end
    end, 0)
  end,
})

vim.api.nvim_create_autocmd('BufDelete', {
  group = vim.api.nvim_create_augroup('region-fold-cleanup', { clear = true }),
  callback = function(ev)
    region_fold_cache[ev.buf] = nil
    region_fold_initialized[ev.buf] = nil
  end,
})

vim.keymap.set('n', '<leader>zc', '<cmd>RegionFoldsCloseAll<CR>', { desc = 'Region Folds: Close All' })
vim.keymap.set('n', '<leader>zo', '<cmd>RegionFoldsOpenAll<CR>', { desc = 'Region Folds: Open All' })
