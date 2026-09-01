--region Lib
local M = {}

-- Resolve the target column (0-indexed) for a cell whose leading pipe sits
-- at `pipe_pos` (1-indexed) in `line`.
local function resolve_after_pipe(line, pipe_pos)
  local len = #line
  local k = pipe_pos + 1
  while k <= len do
    local c = line:sub(k, k)
    if c ~= ' ' and c ~= '\t' then
      break
    end
    k = k + 1
  end

  if k > len then
    -- Nothing but whitespace (or end of line) after the pipe.
    return pipe_pos
  end

  if line:sub(k, k) == '|' then
    -- Empty cell: stop in the space right after the pipe.
    return pipe_pos
  end

  return k - 1 -- convert 1-indexed match position to a 0-indexed column
end

local function find_next_pipe(line, from_col)
  return line:find('|', from_col + 2, true)
end

-- Find the last pipe strictly before the (0-indexed) `from_col`. Returns a
-- 1-indexed position, or nil if there isn't one.
local function find_prev_pipe(line, from_col)
  for k = from_col, 1, -1 do
    if line:sub(k, k) == '|' then
      return k
    end
  end
  return nil
end

-- Find a pipe at or before the (0-indexed) `col`. Returns a 1-indexed
-- position, or nil if there isn't one.
local function find_pipe_at_or_before(line, col)
  for k = col + 1, 1, -1 do
    if line:sub(k, k) == '|' then
      return k
    end
  end
  return nil
end

local function clamp_col(line, col)
  local max_col = math.max(#line - 1, 0)
  if col < 0 then
    return 0
  elseif col > max_col then
    return max_col
  end
  return col
end

function M.next_cell()
  local pos = vim.api.nvim_win_get_cursor(0)
  local line = vim.api.nvim_get_current_line()
  local pipe_pos = find_next_pipe(line, pos[2])
  if not pipe_pos then
    return
  end
  local col = clamp_col(line, resolve_after_pipe(line, pipe_pos))
  vim.api.nvim_win_set_cursor(0, { pos[1], col })
end

function M.prev_cell()
  local pos = vim.api.nvim_win_get_cursor(0)
  local line = vim.api.nvim_get_current_line()
  local col = pos[2]
  local on_pipe = line:sub(col + 1, col + 1) == '|'

  local anchor = find_prev_pipe(line, col)
  if not anchor then
    return
  end

  if not on_pipe then
    -- The nearest pipe behind the cursor only marks the start of the cell
    -- we're already in; go one more pipe back to reach the previous cell.
    anchor = find_prev_pipe(line, anchor - 1) or anchor
  end

  local target = clamp_col(line, resolve_after_pipe(line, anchor))
  vim.api.nvim_win_set_cursor(0, { pos[1], target })
end

-- Resolve the target column for the cell that occupies the same column as
-- `col` on `line` (used when moving up/down a row).
local function resolve_same_column(line, col)
  local anchor = find_pipe_at_or_before(line, col)
  if not anchor then
    return col
  end
  return resolve_after_pipe(line, anchor)
end

local function move_row(delta)
  local pos = vim.api.nvim_win_get_cursor(0)
  local target_row = pos[1] + delta
  local last_row = vim.api.nvim_buf_line_count(0)
  if target_row < 1 or target_row > last_row then
    return false, pos[2]
  end
  return true, pos[2], target_row
end

local function move_row_same_column(delta)
  local ok, col, target_row = move_row(delta)
  if not ok then
    return
  end
  local target_line = vim.api.nvim_buf_get_lines(0, target_row - 1, target_row, false)[1] or ''
  local target_col = clamp_col(target_line, resolve_same_column(target_line, col))
  vim.api.nvim_win_set_cursor(0, { target_row, target_col })
end

function M.down_cell()
  move_row_same_column(1)
end

function M.up_cell()
  move_row_same_column(-1)
end

--endregion

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  callback = function(ev)
    vim.keymap.set({ 'n', 'x', 'o' }, '<C-l>', M.next_cell, { buffer = ev.buf, desc = 'Table: next cell' })
    vim.keymap.set({ 'n', 'x', 'o' }, '<C-h>', M.prev_cell, { buffer = ev.buf, desc = 'Table: previous cell' })
    vim.keymap.set({ 'n', 'x', 'o' }, '<C-j>', M.down_cell, { buffer = ev.buf, desc = 'Table: cell one row down' })
    vim.keymap.set({ 'n', 'x', 'o' }, '<C-k>', M.up_cell, { buffer = ev.buf, desc = 'Table: cell one row up' })
  end,
})
