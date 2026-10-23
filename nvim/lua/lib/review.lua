local M = {}
local group_views = {}

local function run(args, cwd)
  return vim.system(vim.list_extend({ 'git-review' }, args), { cwd = cwd, text = true }):wait()
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

local function status(root)
  local result = run({ 'status', '--json' }, root)
  if result.code == 0 then
    return vim.json.decode(result.stdout)
  end
  result = run({ 'init' }, root)
  if result.code ~= 0 then
    notify_failure(result)
    return nil
  end
  result = run({ 'status', '--json' }, root)
  if result.code ~= 0 then
    notify_failure(result)
    return nil
  end
  return vim.json.decode(result.stdout)
end

local function refresh(view, reviewed_ref)
  if view.left and view.left.type == require('diffview.vcs.rev').RevType.COMMIT then
    view.left.commit = reviewed_ref
  end
  require('diffview').emit 'refresh_files'
end

function M.open()
  local root = toplevel()
  if not root then
    return
  end
  local review = status(root)
  if not review then
    return
  end
  group_views[root] = nil
  local ok, lib = pcall(require, 'diffview.lib')
  local view = ok and lib.get_current_view()
  if view and view.rev_arg == review.reviewedRef then
    return refresh(view, review.reviewedRef)
  end
  vim.cmd({ cmd = 'DiffviewOpen', args = { '-C=' .. root, review.reviewedRef } })
end

function M.open_group()
  local root = toplevel()
  if not root then
    return
  end
  local review = status(root)
  if not review then
    return
  end
  local result = run({ 'group', 'list', '--json' }, root)
  if result.code ~= 0 then
    return notify_failure(result)
  end
  local groups = vim.json.decode(result.stdout)
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
        local display = string.format('%s  %d hunks', group.name, #group.hunks)
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
        local projection = run({ 'group', 'view', '--name', entry.value.name }, root)
        if projection.code ~= 0 then
          return notify_failure(projection)
        end
        local view = vim.json.decode(projection.stdout)
        group_views[root] = entry.value.name
        vim.cmd({ cmd = 'DiffviewOpen', args = { '-C=' .. root, review.reviewedRef .. '..' .. view.ref } })
      end)
      return true
    end,
  }):find()
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
  local review = status(root)
  if not review then
    return
  end
  local group = group_views[root]
  if group then
    local file = view:infer_cur_file(true)
    if not file then
      return vim.notify('review: no file under cursor', vim.log.levels.WARN)
    end
    local result = run({ 'group', 'accept', '--name', group, '--path', file.path }, root)
    if result.code ~= 0 then
      return notify_failure(result)
    end
    group_views[root] = nil
    vim.notify('Accepted grouped changes for ' .. file.path, vim.log.levels.INFO)
    return M.open_group()
  end
  if view.rev_arg ~= review.reviewedRef then
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
  local result = run(args, root)
  if result.code ~= 0 then
    return notify_failure(result)
  end
  vim.notify(vim.trim(result.stdout), vim.log.levels.INFO)
  refresh(view, review.reviewedRef)
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
  local result = run({ 'undo' }, view.adapter.ctx.toplevel)
  if result.code ~= 0 then
    return notify_failure(result)
  end
  vim.notify(vim.trim(result.stdout), vim.log.levels.INFO)
  local review = status(view.adapter.ctx.toplevel)
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
  for _, line in ipairs(vim.json.decode(result.stdout)) do
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
        if view and review then refresh(view, review.reviewedRef) end
      end)
      return true
    end,
  }):find()
end

return M
