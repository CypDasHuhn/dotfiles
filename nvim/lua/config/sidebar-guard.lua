-- Scratch-buffer sidebars (aerial, neo-tree, quickfix, ...) are normal
-- windows as far as :edit/:sb/OpenFile is concerned, so opening a buffer
-- while the cursor sits in one replaces its content instead of opening in
-- the main window. Rather than fixing each plugin's mappings, guard it
-- generally: a real file buffer (buftype = '') never takes over a window
-- that showed a scratch buffer (any other buftype); it opens in the
-- remembered main window instead, and the sidebar keeps its buffer.

local group = vim.api.nvim_create_augroup('sidebar-guard', { clear = true })

local main_win
local sidebar_flags = {} -- winid -> scratch buffer the windows showed
local moving = false

local function is_floating(winid)
  local ok, cfg = pcall(vim.api.nvim_win_get_config, winid)
  return ok and (cfg.relative ~= '' or cfg.external)
end

local function real_buf(bufnr)
  local ok, bt = pcall(vim.api.nvim_get_option_value, 'buftype', { buf = bufnr })
  return ok and bt == ''
end

local function find_main_win(exclude)
  if main_win and main_win ~= exclude and vim.api.nvim_win_is_valid(main_win) and real_buf(vim.api.nvim_win_get_buf(main_win)) then
    return main_win
  end
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if w ~= exclude and not is_floating(w) and real_buf(vim.api.nvim_win_get_buf(w)) then
      return w
    end
  end
  return nil
end

-- A flagged window must show its scratch buffer once everything settles;
-- plugins may swap buffers into it asynchronously after our autocmd.
local function enforce(win, scratch_buf)
  vim.schedule(function()
    if moving or not vim.api.nvim_win_is_valid(win) or not vim.api.nvim_buf_is_valid(scratch_buf) then
      return
    end
    if real_buf(vim.api.nvim_win_get_buf(win)) then
      vim.api.nvim_win_set_buf(win, scratch_buf)
    end
  end)
end

vim.api.nvim_create_autocmd('WinEnter', {
  group = group,
  callback = function()
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_win_get_buf(win)
    if is_floating(win) then
      return
    end
    if real_buf(buf) then
      sidebar_flags[win] = nil
      main_win = win
    else
      sidebar_flags[win] = buf
      -- Scratch buffers are usually unnamed and `bufhidden=wipe` (aerial):
      -- `:edit file` inside the window would reuse them in place (wiping the
      -- sidebar content with nothing left to restore). Name them and keep
      -- them alive when hidden, so the sidebar can be restored.
      if vim.api.nvim_buf_get_name(buf) == '' then
        pcall(vim.api.nvim_buf_set_name, buf, 'sidebar-guard://' .. buf)
      end
      if vim.api.nvim_get_option_value('bufhidden', { buf = buf }) == 'wipe' then
        pcall(vim.api.nvim_set_option_value, 'bufhidden', 'hide', { buf = buf })
      end
    end
  end,
})

vim.api.nvim_create_autocmd('BufWinEnter', {
  group = group,
  callback = function(args)
    if moving then
      return
    end
    local win = vim.api.nvim_get_current_win()
    if not real_buf(args.buf) or is_floating(win) then
      return
    end

    local scratch_buf = sidebar_flags[win]
    sidebar_flags[win] = nil

    if not scratch_buf then
      return
    end

    local target = find_main_win(win)
    if not target then
      -- No real window available: open the buffer in a new vsplit instead,
      -- leaving the sidebar intact.
      vim.cmd('rightbelow vertical sb ' .. args.buf)
      return
    end

    moving = true
    vim.api.nvim_win_set_buf(target, args.buf)
    if vim.fn.winbufnr(win) == args.buf then
      vim.api.nvim_win_set_buf(win, scratch_buf)
    end
    vim.schedule(function()
      if vim.api.nvim_win_is_valid(target) then
        vim.api.nvim_set_current_win(target)
      end
    end)
    moving = false
    main_win = target
    enforce(win, scratch_buf)
  end,
})
