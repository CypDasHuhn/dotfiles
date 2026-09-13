local M = {}

local default_predicates = require 'lib.scopes.predicates'
local default_profiles = require 'lib.scopes.profiles'

local config_cache = {}

local function git_root()
  local root = vim.fs.root(0, '.git')
  if root then
    return root
  end
  return (vim.uv or vim.loop).cwd()
end

local function rel_under(root, path)
  if path == root then
    return nil
  end
  local prefix = root .. '/'
  if path:sub(1, #prefix) == prefix then
    return path:sub(#prefix + 1)
  end
  return nil
end

local function load_config()
  local root = git_root()
  if config_cache[root] then
    return config_cache[root]
  end
  local merged = {
    predicates = vim.deepcopy(default_predicates),
    profiles = vim.deepcopy(default_profiles),
  }
  local path = root .. '/.nvim/scopes.json'
  if vim.fn.filereadable(path) == 1 then
    local ok, data = pcall(function()
      return vim.json.decode(table.concat(vim.fn.readfile(path), '\n'))
    end)
    if ok and type(data) == 'table' then
      for k, v in pairs(data.predicates or {}) do
        merged.predicates[k] = v
      end
      for k, v in pairs(data.profiles or {}) do
        merged.profiles[k] = v
      end
    end
  end
  config_cache[root] = merged
  return merged
end

function M.reload()
  config_cache = {}
end

local function glob_to_lua(glob)
  local out = {}
  local i = 1
  while i <= #glob do
    local c = glob:sub(i, i)
    if c == '*' and glob:sub(i + 1, i + 1) == '*' then
      if glob:sub(i + 2, i + 2) == '/' then
        out[#out + 1] = '(.*/)?'
        i = i + 3
      else
        out[#out + 1] = '.*'
        i = i + 2
      end
    elseif c == '*' then
      out[#out + 1] = '[^/]*'
      i = i + 1
    elseif c == '?' then
      out[#out + 1] = '[^/]'
      i = i + 1
    elseif c:match '[%^%$%(%)%%%.%[%]%+%-]' then
      out[#out + 1] = '%' .. c
      i = i + 1
    else
      out[#out + 1] = c
      i = i + 1
    end
  end
  return '^' .. table.concat(out) .. '$'
end

local function read_head(abs, lines)
  local fd = io.open(abs, 'r')
  if not fd then
    return ''
  end
  local buf = {}
  for _ = 1, lines do
    local line = fd:read '*l'
    if not line then
      break
    end
    buf[#buf + 1] = line
  end
  fd:close()
  return table.concat(buf, '\n')
end

local function clause_matches(clause, rel, abs, ctx)
  if clause.ext then
    local e = vim.fn.fnamemodify(rel, ':e'):lower()
    local found = false
    for _, x in ipairs(clause.ext) do
      if e == x:lower() then
        found = true
        break
      end
    end
    if not found then
      return false
    end
  end
  if clause.basename then
    local name = vim.fn.fnamemodify(rel, ':t')
    local found = false
    for _, g in ipairs(clause.basename) do
      if name:match(glob_to_lua(g)) then
        found = true
        break
      end
    end
    if not found then
      return false
    end
  end
  if clause.path then
    local found = false
    for _, g in ipairs(clause.path) do
      local anchored = g:find('/', 1, true) ~= nil
      if rel:match(glob_to_lua(anchored and g or ('**/' .. g))) then
        found = true
        break
      end
    end
    if not found then
      return false
    end
  end
  if clause.segment then
    local found = false
    for seg in rel:gmatch '[^/]+' do
      for _, want in ipairs(clause.segment) do
        if seg == want then
          found = true
          break
        end
      end
      if found then
        break
      end
    end
    if not found then
      return false
    end
  end
  if clause.hidden ~= nil then
    local is_hidden = vim.fn.fnamemodify(rel, ':t'):sub(1, 1) == '.'
    if is_hidden ~= clause.hidden then
      return false
    end
  end
  if clause.content and not read_head(abs, 64):find(clause.content) then
    return false
  end
  if clause.git and (not ctx or not ctx.match(rel, clause.git)) then
    return false
  end
  return true
end

local function predicate_matches(name, rel, abs, preds, ctx)
  local pred = preds[name]
  if not pred then
    return false
  end
  for _, clause in ipairs(pred) do
    if clause_matches(clause, rel, abs, ctx) then
      return true
    end
  end
  return false
end

local function clause_globs(clause)
  local fields = 0
  for _ in pairs(clause) do
    fields = fields + 1
  end
  if fields ~= 1 then
    return nil
  end
  if clause.ext then
    if #clause.ext == 1 then
      return { '*.' .. clause.ext[1] }
    end
    return { '*.{' .. table.concat(clause.ext, ',') .. '}' }
  end
  if clause.basename then
    return vim.deepcopy(clause.basename)
  end
  if clause.path then
    return vim.deepcopy(clause.path)
  end
  if clause.segment then
    local globs = {}
    for _, seg in ipairs(clause.segment) do
      globs[#globs + 1] = '**/' .. seg .. '/**'
    end
    return globs
  end
  if clause.hidden == true then
    return { '.*' }
  end
  return nil
end

local function compile(preds, names)
  local globs = {}
  for _, name in ipairs(names) do
    local pred = preds[name]
    if not pred then
      return nil
    end
    for _, clause in ipairs(pred) do
      local g = clause_globs(clause)
      if not g then
        return nil
      end
      vim.list_extend(globs, g)
    end
  end
  return globs
end

local function git_context(root, rels)
  local tracked = {}
  for _, p in ipairs(vim.fn.systemlist { 'git', '-C', root, 'ls-files' }) do
    tracked[p] = true
  end
  local ignored = {}
  if #rels > 0 then
    local out = vim.fn.system(
      { 'git', '-C', root, 'check-ignore', '--stdin' },
      table.concat(rels, '\n') .. '\n'
    )
    for _, p in ipairs(vim.split(out, '\n', { plain = true })) do
      if p ~= '' then
        ignored[p] = true
      end
    end
  end
  return {
    match = function(rel, kind)
      if kind == 'tracked' then
        return tracked[rel] == true
      end
      if kind == 'ignored' then
        return ignored[rel] == true
      end
      if kind == 'untracked' then
        return not tracked[rel] and not ignored[rel]
      end
      return false
    end,
  }
end

local function enumerate(root, scan_rel)
  local args = { 'rg', '--files', '--color', 'never', '-g', '!.git' }
  if scan_rel then
    args[#args + 1] = scan_rel
  end
  local res = vim.system(args, { cwd = root, text = true }):wait()
  local out = {}
  for _, line in ipairs(vim.split(res.stdout or '', '\n', { plain = true })) do
    if line ~= '' then
      out[#out + 1] = line
    end
  end
  return out
end

local function slow_files(merged, inc, exc, root, scan_rel)
  local entries = enumerate(root, scan_rel)
  local ctx = git_context(root, entries)
  local files = {}
  for _, rel in ipairs(entries) do
    local abs = root .. '/' .. rel
    local keep = #inc == 0
    if not keep then
      for _, name in ipairs(inc) do
        if predicate_matches(name, rel, abs, merged.predicates, ctx) then
          keep = true
          break
        end
      end
    end
    if keep then
      for _, name in ipairs(exc) do
        if predicate_matches(name, rel, abs, merged.predicates, ctx) then
          keep = false
          break
        end
      end
    end
    if keep then
      files[#files + 1] = abs
    end
  end
  return files
end

local function picker_opts(profile, kind, opts)
  local merged = load_config()
  local def = merged.profiles[profile]
  local inc = (def and def.include) or {}
  local exc = (def and def.exclude) or {}
  if #inc == 0 and #exc == 0 then
    return nil
  end

  local root = git_root()
  local cwd = root
  if opts.cwd then
    cwd = vim.fn.fnamemodify(opts.cwd, ':p'):gsub('/$', '')
  end
  local scan_rel = rel_under(root, cwd)
  if not scan_rel and cwd ~= root then
    root = cwd
  end

  local inc_globs = compile(merged.predicates, inc)
  local exc_globs = compile(merged.predicates, exc)

  if inc_globs and exc_globs then
    if kind == 'find' then
      local cmd = { 'rg', '--files', '--color', 'never' }
      for _, g in ipairs(inc_globs) do
        vim.list_extend(cmd, { '-g', g })
      end
      for _, g in ipairs(exc_globs) do
        vim.list_extend(cmd, { '-g', '!' .. g })
      end
      return { find_command = cmd }
    end
    local args = {}
    for _, g in ipairs(inc_globs) do
      vim.list_extend(args, { '-g', g })
    end
    for _, g in ipairs(exc_globs) do
      vim.list_extend(args, { '-g', '!' .. g })
    end
    return { additional_args = args }
  end

  local files = slow_files(merged, inc, exc, root, scan_rel)
  if #files == 0 then
    if kind == 'find' then
      return { find_command = { 'rg', '--files', '-g', '!*' } }
    end
    return { additional_args = { '-g', '!*' } }
  end
  return { search_dirs = files }
end

function M.find_files(profile, opts)
  opts = vim.deepcopy(opts or {})
  local extra = picker_opts(profile, 'find', opts)
  if extra then
    opts = vim.tbl_extend('force', opts, extra)
  end
  require('telescope.builtin').find_files(opts)
end

function M.live_grep(profile, opts)
  opts = vim.deepcopy(opts or {})
  local extra = picker_opts(profile, 'grep', opts)
  if extra then
    opts = vim.tbl_extend('force', opts, extra)
  end
  require('telescope.builtin').live_grep(opts)
end

function M.profile_names()
  local merged = load_config()
  return vim.tbl_keys(merged.profiles)
end

return M
