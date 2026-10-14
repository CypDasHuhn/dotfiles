local M = {}

local MAX_ENTRIES = 20
local entries = {}
local index = 0
local pending
local pending_timer

local function same_location(a, b)
  if not a or not b or a.row ~= b.row or a.col ~= b.col then
    return false
  end
  if a.path ~= '' or b.path ~= '' then
    return a.path == b.path
  end
  return a.bufnr == b.bufnr
end

local function current_location()
  local position = vim.api.nvim_win_get_cursor(0)
  local bufnr = vim.api.nvim_get_current_buf()
  return {
    path = vim.api.nvim_buf_get_name(bufnr),
    bufnr = bufnr,
    row = position[1],
    col = position[2],
  }
end

local function clear_pending()
  pending = nil
  if pending_timer then
    pending_timer:stop()
    pending_timer:close()
    pending_timer = nil
  end
end

local function trim_history()
  while #entries > MAX_ENTRIES do
    table.remove(entries, 1)
    index = index - 1
  end
end

local function set_location(location)
  clear_pending()

  if location.path ~= '' and vim.api.nvim_buf_get_name(0) ~= location.path then
    vim.cmd('keepjumps edit ' .. vim.fn.fnameescape(location.path))
  elseif location.path == '' and vim.api.nvim_buf_is_valid(location.bufnr) then
    vim.api.nvim_set_current_buf(location.bufnr)
  end

  if vim.api.nvim_buf_is_valid(vim.api.nvim_get_current_buf()) then
    pcall(vim.api.nvim_win_set_cursor, 0, { location.row, location.col })
  end
end

local function ensure_origin(origin)
  if index == 0 then
    entries[1] = origin
    index = 1
    return
  end

  if same_location(entries[index], origin) then
    return
  end

  for position = #entries, index + 1, -1 do
    table.remove(entries, position)
  end
  entries[#entries + 1] = origin
  index = #entries
  trim_history()
end

function M.record(origin, destination)
  if same_location(origin, destination) then
    return
  end

  ensure_origin(origin)
  for position = #entries, index + 1, -1 do
    table.remove(entries, position)
  end

  if not same_location(entries[index], destination) then
    entries[#entries + 1] = destination
    index = #entries
    trim_history()
  end
end

function M.track(jump)
  return function(...)
    clear_pending()
    pending = {
      origin = current_location(),
      win = vim.api.nvim_get_current_win(),
    }
    pending_timer = vim.defer_fn(clear_pending, 10000)
    return jump(...)
  end
end

function M.back()
  clear_pending()
  if index == 0 then
    return
  end
  index = math.max(index - 1, 1)
  set_location(entries[index])
end

function M.forward()
  clear_pending()
  if index == 0 then
    return
  end
  index = math.min(index + 1, #entries)
  set_location(entries[index])
end

local function process_pending()
  if not pending or vim.api.nvim_get_current_win() ~= pending.win then
    return
  end

  local destination = current_location()
  if not same_location(pending.origin, destination) then
    M.record(pending.origin, destination)
    clear_pending()
  end
end

local group = vim.api.nvim_create_augroup('lsp-jump-history', { clear = true })
vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorMoved', 'CursorMovedI' }, {
  group = group,
  callback = function()
    if pending and vim.bo.filetype == 'TelescopePrompt' then
      pending.picker_win = vim.api.nvim_get_current_win()
      return
    end
    vim.schedule(process_pending)
  end,
})

vim.api.nvim_create_autocmd('WinClosed', {
  group = group,
  callback = function(event)
    if not pending or not pending.picker_win or tonumber(event.match) ~= pending.picker_win then
      return
    end
    vim.schedule(function()
      process_pending()
      if pending then
        clear_pending()
      end
    end)
  end,
})

return M
