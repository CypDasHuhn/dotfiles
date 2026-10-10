local region_folds = require 'lib.region-folds'

local M = {}

local TS_MAX = 9
local REGION_STEP = 10

local region_cache = {}
local ts_state = {}

local function resolve(value, prev)
  if type(value) == 'number' then
    return value, ''
  end
  if type(value) ~= 'string' then
    return 0, ''
  end

  local first = value:sub(1, 1)
  if first == '=' then
    return prev, ''
  end
  if first == '>' or first == '<' then
    return tonumber(value:sub(2)) or 0, first
  end
  return tonumber(value) or 0, ''
end

local function ts_level(bufnr, lnum)
  local ok, value = pcall(vim.treesitter.foldexpr, lnum)
  if not ok then
    return 0, ''
  end

  local state = ts_state[bufnr]
  local prev = (state and state.lnum == lnum - 1) and state.level or 0
  local level, marker = resolve(value, prev)
  ts_state[bufnr] = { lnum = lnum, level = level }
  return level, marker
end

local function with_marker(marker, level)
  if marker == '' then
    return level
  end
  return marker .. level
end

local function is_blank(bufnr, lnum)
  local line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1]
  return line == nil or line:match '^%s*$' ~= nil
end

function M.expr(lnum)
  local bufnr = vim.api.nvim_get_current_buf()
  local tick = vim.api.nvim_buf_get_changedtick(bufnr)
  local cached = region_cache[bufnr]

  if not cached or cached.tick ~= tick then
    local levels, starts = region_folds.get_region_levels(bufnr)
    cached = { tick = tick, levels = levels, starts = starts }
    region_cache[bufnr] = cached
    ts_state[bufnr] = nil
  end

  local region = cached.levels[lnum] or 0
  local level, marker = ts_level(bufnr, lnum)
  level = math.min(level, TS_MAX)

  if region == 0 then
    if level > 0 and marker ~= '>' then
      local next_level, next_marker = ts_level(bufnr, lnum + 1)
      if next_level == 0 or (next_marker == '>' and next_level <= level) then
        if is_blank(bufnr, lnum) then
          return 0
        end
        if cached.starts[lnum + 1] then
          return '<' .. level
        end
      end
    end
    return with_marker(marker, level)
  end
  if cached.starts[lnum] then
    return with_marker('>', region * REGION_STEP)
  end
  return with_marker(marker, region * REGION_STEP + level)
end

function M.text()
  local dashes = vim.v.folddashes
  local start = vim.v.foldstart
  local stop = vim.v.foldend
  local line = vim.fn.getline(start)
  local name = line:match 'region%s+(.-)%s*$'
  local label = (name and name ~= '') and name or line:gsub('^%s*', '')

  local suffix = ('  %d lines'):format(stop - start + 1)
  local width = vim.fn.winwidth(0) - vim.fn.strdisplaywidth(dashes) - 1
  local avail = width - vim.fn.strdisplaywidth(suffix)
  if avail > 0 then
    label = vim.fn.strcharpart(label, 0, avail)
  end

  if name and name ~= '' then
    return {
      { label, 'FoldRegionName' },
      { suffix, 'FoldRegionLines' },
    }
  end

  return dashes .. ' ' .. label .. suffix
end

local function ts_ready(bufnr)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok or not parser then
    return true
  end

  local limit = math.min(vim.api.nvim_buf_line_count(bufnr), 400)
  for lnum = 1, limit do
    local ok2, value = pcall(vim.treesitter.foldexpr, lnum)
    if ok2 and resolve(value, 0) > 0 then
      return true
    end
  end

  return false
end

function M.close_regions(bufnr, starts, attempt)
  attempt = attempt or 0

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  starts = starts or select(2, region_folds.get_region_levels(bufnr))
  local list = {}
  for lnum in pairs(starts) do
    list[#list + 1] = lnum
  end
  table.sort(list)
  if #list == 0 then
    return
  end

  pcall(function()
    local parser = vim.treesitter.get_parser(bufnr)
    if parser then
      parser:parse(true)
    end
  end)

  if not ts_ready(bufnr) and attempt < 20 then
    vim.defer_fn(function()
      M.close_regions(bufnr, starts, attempt + 1)
    end, 25)
    return
  end

  for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
    vim.api.nvim_win_call(win, function()
      local saved = vim.api.nvim_win_get_cursor(0)
      for _, lnum in ipairs(list) do
        if lnum > 1 and vim.fn.foldlevel(lnum) > vim.fn.foldlevel(lnum - 1) then
          pcall(vim.api.nvim_win_set_cursor, 0, { lnum, 0 })
          pcall(vim.cmd, 'normal! zc')
        end
      end
      pcall(vim.api.nvim_win_set_cursor, 0, saved)
    end)
  end
end

function M.clear(bufnr)
  region_cache[bufnr] = nil
  ts_state[bufnr] = nil
end

return M
