local M = {}

M.config = {
  ref_prefix = 'refs/reviews/',
  base = nil,
}

local function git(args, cwd, env)
  local cmd = { 'git' }
  vim.list_extend(cmd, args)
  return vim.system(cmd, { cwd = cwd, text = true, env = env }):wait()
end

local function git_out(args, cwd, env)
  local res = git(args, cwd, env)
  if res.code ~= 0 then
    error(('git %s: %s'):format(table.concat(args, ' '), vim.trim(res.stderr or '')))
  end
  return vim.trim(res.stdout or '')
end

local function git_ok(args, cwd)
  return git(args, cwd).code == 0
end

local function git_lines(args, cwd)
  local res = git(args, cwd)
  if res.code ~= 0 then
    error(('git %s: %s'):format(table.concat(args, ' '), vim.trim(res.stderr or '')))
  end
  local out = {}
  for line in vim.gsplit(res.stdout or '', '\n', { plain = true }) do
    if line ~= '' then
      out[#out + 1] = line
    end
  end
  return out
end

local function toplevel()
  return git_out({ 'rev-parse', '--show-toplevel' }, vim.uv.cwd())
end

local function branch(tl)
  local b = git_out({ 'rev-parse', '--abbrev-ref', 'HEAD' }, tl)
  return b == 'HEAD' and 'detached' or b
end

local function review_ref(tl)
  return M.config.ref_prefix .. branch(tl)
end

local function resolve_base(tl)
  if M.config.base then
    return M.config.base
  end
  if git_ok({ 'rev-parse', '--verify', '--quiet', 'origin/HEAD' }, tl) then
    return 'origin/HEAD'
  end
  return 'HEAD'
end

local function ensure_ref(tl)
  local ref = review_ref(tl)
  if not git_ok({ 'rev-parse', '--verify', '--quiet', ref }, tl) then
    local base = git_out({ 'rev-parse', '--verify', resolve_base(tl) }, tl)
    git_out({ 'update-ref', ref, base }, tl)
  end
  return ref
end

function M.accept(tl, path, oldpath)
  local ref = ensure_ref(tl)
  local head = git_out({ 'rev-parse', ref }, tl)
  local index = vim.fn.tempname()
  local env = { GIT_INDEX_FILE = index }

  local ok, changed = pcall(function()
    git_out({ 'read-tree', head }, tl, env)

    local paths = { path }
    if oldpath and oldpath ~= '' then
      paths[#paths + 1] = oldpath
    end
    git_out(vim.list_extend({ 'add', '-A', '--' }, paths), tl, env)

    local tree = git_out({ 'write-tree' }, tl, env)
    if tree == git_out({ 'rev-parse', head .. '^{tree}' }, tl) then
      return false
    end

    local new = git_out({ 'commit-tree', tree, '-p', head, '-m', 'accept: ' .. path }, tl)
    git_out({ 'update-ref', ref, new, head }, tl)
    return true
  end)

  vim.fn.delete(index)
  if not ok then
    error(changed)
  end
  return changed
end

function M.undo(tl)
  local ref = review_ref(tl)
  local cur = git_out({ 'rev-parse', '--verify', ref }, tl)
  local subject = git_out({ 'log', '-1', '--format=%s', cur }, tl)
  if not subject:match '^accept:' then
    return false, 'nothing to un-accept'
  end
  local parent = git_out({ 'rev-parse', '--verify', cur .. '^' }, tl)
  git_out({ 'update-ref', ref, parent, cur }, tl)
  return true, subject
end

local function refresh_view(view)
  local tl = view.adapter.ctx.toplevel
  local ref = review_ref(tl)
  if view.rev_arg == ref and view.left and view.left.type == require('diffview.vcs.rev').RevType.COMMIT then
    view.left.commit = git_out({ 'rev-parse', '--verify', ref }, tl)
  end
  require('diffview').emit 'refresh_files'
end

function M.accept_current()
  local ok, lib = pcall(require, 'diffview.lib')
  if not ok then
    return vim.notify('review: diffview not loaded', vim.log.levels.WARN)
  end

  local view = lib.get_current_view()
  if not view then
    return vim.notify('review: no diffview open', vim.log.levels.WARN)
  end

  local file = view:infer_cur_file()
  if not file then
    return vim.notify('review: no entry under cursor', vim.log.levels.WARN)
  end

  local ok2, changed = pcall(M.accept, view.adapter.ctx.toplevel, file.path, file.oldpath)
  if not ok2 then
    return vim.notify('review: ' .. tostring(changed), vim.log.levels.ERROR)
  end

  vim.notify(
    changed and ('review: accepted ' .. file.path) or ('review: ' .. file.path .. ' already accepted'),
    vim.log.levels.INFO
  )
  refresh_view(view)
end

function M.undo_current()
  local ok, lib = pcall(require, 'diffview.lib')
  if not ok then
    return vim.notify('review: diffview not loaded', vim.log.levels.WARN)
  end

  local view = lib.get_current_view()
  if not view then
    return vim.notify('review: no diffview open', vim.log.levels.WARN)
  end

  local ok2, undone, subject = pcall(M.undo, view.adapter.ctx.toplevel)
  if not ok2 then
    return vim.notify('review: ' .. tostring(undone), vim.log.levels.ERROR)
  end

  vim.notify(undone and ('review: un-accepted ' .. subject) or 'review: nothing to un-accept', vim.log.levels.INFO)
  if undone then
    refresh_view(view)
  end
end

function M.open()
  local tl = toplevel()
  local ref = ensure_ref(tl)
  local ok, lib = pcall(require, 'diffview.lib')
  local view = ok and lib.get_current_view()
  if view and view.rev_arg == ref then
    return refresh_view(view)
  end
  vim.cmd('DiffviewOpen ' .. vim.fn.fnameescape(ref))
end

local function collect_accepts(tl, ref)
  local entries = {}
  for _, line in ipairs(git_lines({ 'log', '--format=%H%x09%h%x09%cr%x09%s', ref }, tl)) do
    local sha, short, rel, subject = line:match '^(%x+)\t(%x+)\t(.-)\t(.*)$'
    entries[#entries + 1] = {
      value = sha,
      short = short,
      rel = rel,
      subject = subject,
      display = ('%s  %-16s %s'):format(short, rel, subject),
    }
    if not subject:match '^accept:' then
      break
    end
  end
  return entries
end

function M.reset(tl, ref, sha)
  local cur = git_out({ 'rev-parse', '--verify', ref }, tl)
  sha = git_out({ 'rev-parse', '--verify', sha }, tl)
  if sha == cur then
    return false, 'already at ' .. sha:sub(1, 7)
  end
  git_out({ 'update-ref', ref, sha, cur }, tl)
  return true
end

local function apply_reset(tl, ref, entry)
  local ok, changed = pcall(M.reset, tl, ref, entry.value)
  if not ok then
    return vim.notify('review: ' .. tostring(changed), vim.log.levels.ERROR)
  end
  vim.notify(
    changed and ('review: reset to ' .. entry.short .. ' (' .. entry.rel .. ')') or ('review: ' .. changed),
    vim.log.levels.INFO
  )
  local lib = require 'diffview.lib'
  local view = lib and lib.get_current_view()
  if view then
    refresh_view(view)
  end
end

function M.log()
  local tl = toplevel()
  local ref = ensure_ref(tl)
  local entries = collect_accepts(tl, ref)

  local ok, pickers = pcall(require, 'telescope.pickers')
  if not ok then
    return vim.ui.select(entries, {
      prompt = 'Accepted (' .. ref .. ')',
      format_item = function(e)
        return e.display
      end,
    }, function(entry)
      if entry then
        apply_reset(tl, ref, entry)
      end
    end)
  end

  local finders = require 'telescope.finders'
  local conf = require('telescope.config').values
  local previewers = require 'telescope.previewers'
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'

  pickers.new({}, {
    prompt_title = 'Accepted (' .. ref .. ')',
    finder = finders.new_table {
      results = entries,
      entry_maker = function(e)
        return { value = e.value, display = e.display, ordinal = e.subject .. ' ' .. e.short, entry = e }
      end,
    },
    sorter = conf.generic_sorter {},
    previewer = previewers.new_buffer_previewer {
      define_preview = function(self, entry)
        local lines = git_lines({ 'show', '--stat', '--patch', entry.value }, tl)
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        vim.bo[self.state.bufnr].filetype = 'git'
      end,
    },
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if not entry then
          return
        end
        if vim.fn.confirm(('Reset accepted to %s (%s)?'):format(entry.entry.short, entry.entry.rel), '&Yes\n&No', 2) == 1 then
          apply_reset(tl, ref, entry.entry)
        end
      end)
      return true
    end,
  }):find()
end

return M
