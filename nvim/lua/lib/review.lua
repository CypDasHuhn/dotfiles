local M = {}
local group_views = {}
local pending_operations = {}
local review_refs = {}

local function as_list(value)
  if type(value) == 'table' then
    return value
  end
  return {}
end

local function capture_view_state(view)
  local state = {
    path = view.panel.cur_file and view.panel.cur_file.path,
    panel_focused = view.panel:is_focused(),
    cursors = {},
    active_symbol = nil,
  }
  local current_window = vim.api.nvim_get_current_win()
  for _, window in ipairs(view.cur_layout.windows or {}) do
    if vim.api.nvim_win_is_valid(window.id) and window.file and window.file.symbol then
      state.cursors[window.file.symbol] = {
        cursor = vim.api.nvim_win_get_cursor(window.id),
      }
      if window.id == current_window then
        state.active_symbol = window.file.symbol
      end
    end
  end
  if state.panel_focused and view.panel.winid and vim.api.nvim_win_is_valid(view.panel.winid) then
    state.panel_cursor = vim.api.nvim_win_get_cursor(view.panel.winid)
  end
  return state
end

local function find_view_file(view, path)
  if not path then
    return nil
  end
  for _, file in view.files:iter() do
    if file.path == path or file.oldpath == path then
      return file
    end
  end
end

local function restore_view_state(view, state)
  local file = find_view_file(view, state.path)
  if file and view.cur_entry ~= file then
    view.emitter:once('file_open_post', function(_, opened_file)
      if opened_file == file then
        vim.schedule(function()
          restore_view_state(view, state)
        end)
      end
    end)
    view:set_file(file, false, true)
    return
  end
  if file then
    for _, window in ipairs(view.cur_layout.windows or {}) do
      local symbol = window.file and window.file.symbol
      local saved = symbol and state.cursors[symbol]
      if saved and window.file.bufnr and vim.api.nvim_win_is_valid(window.id) and vim.api.nvim_buf_is_valid(window.file.bufnr) then
        local line_count = vim.api.nvim_buf_line_count(window.file.bufnr)
        local line = math.max(1, math.min(saved.cursor[1], line_count))
        local content = vim.api.nvim_buf_get_lines(window.file.bufnr, line - 1, line, false)[1] or ''
        local column = math.min(saved.cursor[2], #content)
        pcall(vim.api.nvim_win_set_cursor, window.id, { line, column })
      end
    end
  end
  if state.panel_cursor and view.panel.winid and vim.api.nvim_win_is_valid(view.panel.winid) then
    local line_count = vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(view.panel.winid))
    local line = math.max(1, math.min(state.panel_cursor[1], line_count))
    pcall(vim.api.nvim_win_set_cursor, view.panel.winid, { line, state.panel_cursor[2] })
  end
  if state.panel_focused then
    view.panel:focus()
  elseif state.active_symbol then
    for _, window in ipairs(view.cur_layout.windows or {}) do
      if window.file and window.file.symbol == state.active_symbol and vim.api.nvim_win_is_valid(window.id) then
        vim.api.nvim_set_current_win(window.id)
        break
      end
    end
  end
end

local function open_diffview(root, revision, state)
  local lib = require 'diffview.lib'
  local current = lib.get_current_view()
  if current then
    current:close()
    lib.dispose_view(current)
  end
  local args = { '-C=' .. root, revision }
  if state and state.path then
    args[#args + 1] = '--selected-file=' .. state.path
  end
  vim.cmd({ cmd = 'DiffviewOpen', args = args })
  local view = lib.get_current_view()
  if view and state then
    view.emitter:once('files_updated', function()
      vim.schedule(function()
        if lib.get_current_view() == view then
          restore_view_state(view, state)
        end
      end)
    end)
  end
  return view
end

local function run(args, cwd)
  return vim.system(vim.list_extend({ 'git-review' }, args), { cwd = cwd, text = true }):wait()
end

local function run_async(args, cwd, callback)
  vim.system(vim.list_extend({ 'git-review' }, args), { cwd = cwd, text = true }, function(result)
    vim.schedule(function()
      callback(result)
    end)
  end)
end

local function begin_operation(root)
  if pending_operations[root] then
    vim.notify('review: an operation is already running', vim.log.levels.WARN)
    return false
  end
  pending_operations[root] = true
  return true
end

local function end_operation(root)
  pending_operations[root] = nil
end

local function notify_failure(result)
  vim.notify(vim.trim(result.stderr or result.stdout or 'git-review failed'), vim.log.levels.ERROR)
end

local function toplevel()
  local result = vim.system({ 'git', 'rev-parse', '--show-toplevel' }, { cwd = vim.uv.cwd(), text = true }):wait()
  if result.code ~= 0 then
    notify_failure(result)
    return nil
  end
  return vim.trim(result.stdout)
end

local function status(root, initialize)
  local result = run({ 'status', '--no-init', '--json' }, root)
  if result.code ~= 0 then
    notify_failure(result)
    return nil
  end
  local review = vim.json.decode(result.stdout)
  if review.sessionExists then
    review_refs[root] = review.reviewedRef
    return review
  end
  review_refs[root] = nil
  if not initialize then
    return nil
  end
  result = run({ 'init' }, root)
  if result.code ~= 0 then
    notify_failure(result)
    return nil
  end
  return status(root, false)
end

local function ensure_status(root)
  return status(root, true)
end

local function refresh(view, reviewed_ref, state)
  local root = view.adapter.ctx.toplevel
  open_diffview(root, reviewed_ref, state)
end

function M.open()
  local root = toplevel()
  if not root then
    return
  end
  local review = ensure_status(root)
  if not review then
    return
  end
  group_views[root] = nil
  local ok, lib = pcall(require, 'diffview.lib')
  local view = ok and lib.get_current_view()
  if view and view.rev_arg == review.reviewedRef then
    return refresh(view, review.reviewedRef, capture_view_state(view))
  end
  open_diffview(root, review.reviewedRef)
end

local function open_group_view(root, name, state)
  local reviewed_ref = review_refs[root]
  if not reviewed_ref then
    local review = status(root, false)
    if not review then
      return
    end
    reviewed_ref = review.reviewedRef
  end
  run_async({ 'group', 'project', '--name', name }, root, function(projection)
    if projection.code ~= 0 then
      return notify_failure(projection)
    end
    local view = vim.json.decode(projection.stdout)
    local fragments = as_list(view.fragments)
    local blocked = as_list(view.blocked)
    if view.complete then
      group_views[root] = nil
      vim.notify('review: group is complete', vim.log.levels.INFO)
      return M.open()
    end
    if #fragments == 0 then
      group_views[root] = nil
      vim.notify('review: group is blocked by dependencies', vim.log.levels.WARN)
      return M.open()
    end
    if #blocked > 0 then
      vim.notify(string.format('review: %d group fragments are blocked by dependencies', #blocked), vim.log.levels.WARN)
    end
    group_views[root] = { name = name, ref = view.ref, reviewedRef = reviewed_ref }
    open_diffview(root, reviewed_ref .. '..' .. view.ref, state)
  end)
end

function M.open_group()
  local root = toplevel()
  if not root then
    return
  end
  local review = ensure_status(root)
  if not review then
    return
  end
  local result = run({ 'group', 'list', '--json' }, root)
  if result.code ~= 0 then
    return notify_failure(result)
  end
  local groups = as_list(vim.json.decode(result.stdout))
  if #groups == 0 then
    return vim.notify('review: no review groups', vim.log.levels.INFO)
  end
  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local conf = require('telescope.config').values
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'
  pickers.new({}, {
    prompt_title = 'Review groups',
    finder = finders.new_table({
      results = groups,
      entry_maker = function(group)
        local fragments = as_list(group.fragments)
        local display = string.format('%s  %d fragments', group.name, #fragments)
        return { value = group, display = display, ordinal = display }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if not entry then
          return
        end
        open_group_view(root, entry.value.name)
      end)
      return true
    end,
  }):find()
end

function M.assign_current()
  local ok, lib = pcall(require, 'diffview.lib')
  if not ok then
    return vim.notify('review: Diffview is not loaded', vim.log.levels.WARN)
  end
  local view = lib.get_current_view()
  if not view then
    return vim.notify('review: no Diffview is open', vim.log.levels.WARN)
  end
  local root = view.adapter.ctx.toplevel
  if not status(root, false) then
    return vim.notify('review: no review session exists', vim.log.levels.WARN)
  end
  local file = view:infer_cur_file(true)
  if not file then
    return vim.notify('review: no file under cursor', vim.log.levels.WARN)
  end
  vim.ui.input({ prompt = 'Review group: ' }, function(name)
    name = name and vim.trim(name) or ''
    if name == '' then
      return
    end
    local args = { 'group', 'assign', '--name', name, '--path', file.path, '--json' }
    if file.oldpath and file.oldpath ~= file.path then
      vim.list_extend(args, { '--path', file.oldpath })
    end
    local result = run(args, root)
    if result.code ~= 0 then
      return notify_failure(result)
    end
    local assignment = vim.json.decode(result.stdout)
    vim.notify(string.format('Assigned %d of %d fragments to %s', assignment.assigned or 0, assignment.matched or 0, name), vim.log.levels.INFO)
  end)
end

function M.accept_current()
  local ok, lib = pcall(require, 'diffview.lib')
  if not ok then
    return vim.notify('review: Diffview is not loaded', vim.log.levels.WARN)
  end
  local view = lib.get_current_view()
  if not view then
    return vim.notify('review: no Diffview is open', vim.log.levels.WARN)
  end
  local root = view.adapter.ctx.toplevel
  local group_view = group_views[root]
  local reviewed_ref = review_refs[root]
  if not group_view and not reviewed_ref then
    local review = status(root, false)
    if not review then
      return vim.notify('review: no review session exists', vim.log.levels.WARN)
    end
    reviewed_ref = review.reviewedRef
  end
  if group_view then
    local group = group_view.name
    local file = view:infer_cur_file(true)
    if not file then
      return vim.notify('review: no file under cursor', vim.log.levels.WARN)
    end
    local args = { 'group', 'accept', '--name', group, '--path', file.path }
    if file.oldpath and file.oldpath ~= file.path then
      vim.list_extend(args, { '--path', file.oldpath })
    end
    if not begin_operation(root) then
      return
    end
    local state = capture_view_state(view)
    vim.notify(string.format('Accepting grouped fragments for %s', file.path), vim.log.levels.INFO)
    return run_async(args, root, function(result)
      end_operation(root)
      if result.code ~= 0 then
        return notify_failure(result)
      end
      local accepted = vim.json.decode(result.stdout)
      vim.notify(string.format('Accepted %d grouped fragments for %s', #as_list(accepted.accepted), file.path), vim.log.levels.INFO)
      if lib.get_current_view() ~= view then
        return vim.notify('review: accepted changes; the Diffview was changed before refresh', vim.log.levels.WARN)
      end
      open_group_view(root, group, state)
    end)
  end
  if view.rev_arg ~= reviewed_ref then
    return vim.notify('review: open the reviewed-state view first', vim.log.levels.WARN)
  end
  local file = view:infer_cur_file(true)
  if not file then
    return vim.notify('review: no file under cursor', vim.log.levels.WARN)
  end
  local args = { 'accept', '--path', file.path }
  if file.oldpath and file.oldpath ~= file.path then
    vim.list_extend(args, { '--path', file.oldpath })
  end
  if not begin_operation(root) then
    return
  end
  local state = capture_view_state(view)
  vim.notify(string.format('Accepting fragments for %s', file.path), vim.log.levels.INFO)
  run_async(args, root, function(result)
    end_operation(root)
    if result.code ~= 0 then
      return notify_failure(result)
    end
    local accepted = vim.json.decode(result.stdout)
    local message = string.format('Accepted %d fragments (%d materialized, %d pending)', #as_list(accepted.accepted), #as_list(accepted.materialized), #as_list(accepted.pending))
    local reconciled = as_list(accepted.reconciled)
    if #reconciled > 0 then
      message = message .. string.format(', %d stale paths reconciled', #reconciled)
    end
    vim.notify(message, vim.log.levels.INFO)
    if lib.get_current_view() ~= view then
      return vim.notify('review: accepted changes; the Diffview was changed before refresh', vim.log.levels.WARN)
    end
    refresh(view, reviewed_ref, state)
  end)
end

function M.undo_current()
  local ok, lib = pcall(require, 'diffview.lib')
  if not ok then
    return vim.notify('review: Diffview is not loaded', vim.log.levels.WARN)
  end
  local view = lib.get_current_view()
  if not view then
    return vim.notify('review: no Diffview is open', vim.log.levels.WARN)
  end
  local root = view.adapter.ctx.toplevel
  local group_view = group_views[root]
  local result = run({ 'undo' }, root)
  if result.code ~= 0 then
    return notify_failure(result)
  end
  vim.notify(vim.trim(result.stdout), vim.log.levels.INFO)
  if group_view then
    return open_group_view(root, group_view.name)
  end
  local review = status(root, false)
  if review then
    refresh(view, review.reviewedRef)
  end
end

function M.log()
  local root = toplevel()
  if not root then return end
  local result = run({ 'history' }, root)
  if result.code ~= 0 then return notify_failure(result) end
  local entries = {}
  for _, line in ipairs(as_list(vim.json.decode(result.stdout))) do
    local sha, short, relative, subject = line:match('^(%x+)\t(%x+)\t(.-)\t(.*)$')
    if sha then entries[#entries + 1] = { sha = sha, display = short .. '  ' .. relative .. '  ' .. subject } end
  end
  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local conf = require('telescope.config').values
  local previewers = require 'telescope.previewers'
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'
  pickers.new({}, {
    prompt_title = 'Accepted changes',
    finder = finders.new_table({ results = entries, entry_maker = function(entry) return { value = entry, display = entry.display, ordinal = entry.display } end }),
    sorter = conf.generic_sorter({}),
    previewer = previewers.new_buffer_previewer({ define_preview = function(self, entry) local output = vim.system({ 'git', '-C', root, 'show', '--stat', '--patch', entry.value.sha }, { text = true }):wait(); vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(output.stdout, '\n')); vim.bo[self.state.bufnr].filetype = 'git' end }),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if not entry or vim.fn.confirm('Reset reviewed state to ' .. entry.value.sha:sub(1, 7) .. '?', '&Yes\n&No', 2) ~= 1 then return end
        local reset = run({ 'reset', '--commit', entry.value.sha }, root)
        if reset.code ~= 0 then return notify_failure(reset) end
        local ok, lib = pcall(require, 'diffview.lib')
        local view = ok and lib.get_current_view()
        local review = status(root)
        if group_views[root] then
          group_views[root] = nil
          return M.open()
        end
        if view and review then refresh(view, review.reviewedRef) end
      end)
      return true
    end,
  }):find()
end

return M
