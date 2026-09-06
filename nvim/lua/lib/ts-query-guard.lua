-- Guard against treesitter query errors (usually parser/query version drift).
--
-- A query file that fails to parse currently makes the highlighter raise
-- inside the decoration provider, which Neovim prints to the message area and
-- forces a hit-enter prompt. This module wraps vim.treesitter.query.get so a
-- broken query behaves like a missing one: that feature quietly disables for
-- the language instead of exploding the screen. The first failure per language
-- is reported through vim.notify and offered a repair (reinstall the parser,
-- optionally after updating nvim-treesitter so its parser pins advance).
--
-- The replacement keeps the memoized object's API: vim.treesitter.query.set()
-- calls `query.get:clear(...)` to invalidate the cache, so the wrapper forwards
-- `clear` and drops its own negative entries at the same time.

local uv = vim.uv

local query_mod = vim.treesitter.query
-- The original is a vim.func._memoize object (callable, with a `clear` method).
local inner_get = query_mod.get

local patched = false
local opts = {}

-- broken[lang][query_name] = error message
local broken = {}
-- last_attempt[lang][query_name] = uv.now() of the last failed parse attempt
local last_attempt = {}
-- repair dialog offered once per language per session
local prompted = {}
-- repair currently running per language
local repairing = {}

local install_dirs = {
  vim.fn.stdpath 'data' .. '/site/parser',
  vim.fn.stdpath 'data' .. '/lazy/nvim-treesitter/parser',
}

local DEBOUNCE_MS = 3000
local REPAIR_TIMEOUT_MS = 120000

local M = {}

local function managed_parser_paths(lang)
  local found = {}
  for _, dir in ipairs(install_dirs) do
    local path = dir .. '/' .. lang .. '.so'
    if uv.fs_stat(path) then
      found[#found + 1] = path
    end
  end
  return found
end

local function parser_signature(lang)
  local parts = {}
  for _, path in ipairs(managed_parser_paths(lang)) do
    local st = uv.fs_stat(path)
    if st then
      parts[#parts + 1] = string.format('%s:%s:%s:%s', path, st.size, st.mtime.sec, st.mtime.nsec)
    end
  end
  return table.concat(parts, '|')
end

local function parser_changed(lang, signature_before)
  -- A temporarily missing .so (mid-rebuild) must not count as "done".
  if #managed_parser_paths(lang) == 0 then
    return false
  end
  return parser_signature(lang) ~= signature_before
end

local function first_line(msg)
  return tostring(msg):match '^([^\n]+)' or tostring(msg)
end

local function notify(title, msg, level)
  vim.schedule(function()
    vim.notify(msg, level, { title = title })
  end)
end

-- Forward declarations so report_broken/offer_repair/run_fix can reference each other.
local report_broken
local offer_repair
local run_fix

local function clear_broken(lang, query_name)
  if lang then
    if broken[lang] then
      if query_name then
        broken[lang][query_name] = nil
        if last_attempt[lang] then
          last_attempt[lang][query_name] = nil
        end
      else
        broken[lang] = nil
        last_attempt[lang] = nil
      end
    end
  else
    broken = {}
    last_attempt = {}
  end
end

report_broken = function(lang, query_name, err)
  if broken[lang] and broken[lang][query_name] then
    return
  end
  broken[lang] = broken[lang] or {}
  broken[lang][query_name] = err

  vim.schedule(function()
    local parser_paths = managed_parser_paths(lang)
    local query_files = vim.api.nvim_get_runtime_file('queries/' .. lang .. '/' .. query_name .. '.scm', true)
    local query_file = query_files[1]
    local msg = string.format(
      'Query "%s" failed to compile (%s). Treesitter highlighting is disabled for %s until the parser/query mismatch is fixed.',
      query_name,
      first_line(err),
      lang
    )
    if query_file then
      msg = msg .. '\nQuery: ' .. query_file
    end
    if #parser_paths > 0 then
      msg = msg .. '\nParser: ' .. parser_paths[#parser_paths]
    end
    vim.notify(msg, vim.log.levels.WARN, { title = 'treesitter: ' .. lang })
  end)

  if #managed_parser_paths(lang) > 0 then
    offer_repair(lang)
  end
end

local function restart_lang_buffers(lang)
  vim.schedule(function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then
        local ft = vim.bo[buf].filetype
        if ft ~= '' then
          local buffer_lang = vim.treesitter.language.get_lang(ft) or ft
          if buffer_lang == lang and opts.is_enabled and opts.is_enabled(lang) then
            pcall(vim.treesitter.stop, buf)
            pcall(vim.treesitter.start, buf, lang)
          end
        end
      end
    end
  end)
end

local function finish_repair(lang, success)
  repairing[lang] = false
  prompted[lang] = false
  clear_broken(lang)
  if success then
    notify('treesitter: ' .. lang, 'Parser updated. Treesitter highlighting restored.', vim.log.levels.INFO)
    restart_lang_buffers(lang)
  else
    notify(
      'treesitter: ' .. lang,
      'Parser did not change after the repair ran. If it is still broken, the installed parser is already the newest nvim-treesitter provides; you may need to update Neovim (its runtime queries) or report the mismatch.',
      vim.log.levels.WARN
    )
  end
end

run_fix = function(lang, update_plugin)
  if repairing[lang] then
    return
  end
  repairing[lang] = true

  local signature_before = parser_signature(lang)
  local started = uv.now()
  local finished = false

  local function finish(success)
    if finished then
      return
    end
    finished = true
    finish_repair(lang, success)
  end

  local function poll()
    if parser_changed(lang, signature_before) then
      finish(true)
    elseif uv.now() - started > REPAIR_TIMEOUT_MS then
      finish(false)
    else
      vim.defer_fn(poll, 1000)
    end
  end

  local function do_install()
    notify('treesitter: ' .. lang, 'Reinstalling the parser (TSInstall).', vim.log.levels.INFO)
    vim.schedule(function()
      pcall(vim.cmd, 'TSInstall! ' .. lang)
    end)
    poll()
  end

  if not update_plugin then
    do_install()
    return
  end

  notify('treesitter: ' .. lang, 'Updating nvim-treesitter, then reinstalling the parser.', vim.log.levels.INFO)
  local lazy_done = false
  local group = vim.api.nvim_create_augroup('TsQueryGuardLazy', { clear = true })
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'LazyDone',
    once = true,
    callback = function()
      lazy_done = true
    end,
  })
  vim.schedule(function()
    pcall(vim.cmd, 'Lazy update nvim-treesitter')
  end)

  local waited = 0
  local function await_lazy()
    waited = waited + 1000
    if lazy_done or waited > REPAIR_TIMEOUT_MS then
      do_install()
    else
      vim.defer_fn(await_lazy, 1000)
    end
  end
  vim.defer_fn(await_lazy, 1000)
end

offer_repair = function(lang)
  if prompted[lang] or repairing[lang] then
    return
  end
  prompted[lang] = true

  vim.schedule(function()
    local first_broken
    for query_name, err in pairs(broken[lang] or {}) do
      first_broken = { query_name = query_name, err = err }
      break
    end
    if not first_broken then
      return
    end

    local items = {
      { label = 'Update nvim-treesitter, then reinstall parser', value = 'update' },
      { label = 'Reinstall parser only', value = 'reinstall' },
      { label = 'Dismiss (this session)', value = 'dismiss' },
    }
    vim.ui.select(items, {
      prompt = string.format(
        'Treesitter query error in %s (%s): %s\nHighlighting stays disabled until the parser is fixed.',
        lang,
        first_broken.query_name,
        first_line(first_broken.err)
      ),
      format_item = function(item)
        return item.label
      end,
    }, function(choice)
      if not choice then
        prompted[lang] = false
        return
      end
      if choice.value == 'dismiss' then
        return
      end
      run_fix(lang, choice.value == 'update')
    end)
  end)
end

local function guarded_call(lang, query_name, ...)
  if type(lang) ~= 'string' or type(query_name) ~= 'string' then
    return inner_get(lang, query_name, ...)
  end

  local now = uv.now()
  local known_broken = broken[lang] and broken[lang][query_name]
  local last_try = last_attempt[lang] and last_attempt[lang][query_name]
  if known_broken and now - (last_try or 0) < DEBOUNCE_MS then
    return
  end

  local packed = vim.F.pack_len(pcall(inner_get, lang, query_name, ...))
  local ok = packed[1]
  if ok then
    if broken[lang] then
      clear_broken(lang, query_name)
    end
    return unpack(packed, 2, packed.n)
  end

  last_attempt[lang] = last_attempt[lang] or {}
  last_attempt[lang][query_name] = now
  report_broken(lang, query_name, packed[2])
end

---@param config { is_enabled?: fun(lang: string): boolean }
function M.setup(config)
  opts = config or {}
  if not patched then
    patched = true

    local guarded = setmetatable({}, {
      __call = function(_, ...)
        return guarded_call(...)
      end,
    })

    ---@param self table
    ---@param ... any forward to the memoized clear()
    function guarded.clear(self, ...)
      inner_get:clear(...)
      if select('#', ...) == 0 then
        clear_broken()
      elseif select(1, ...) then
        clear_broken(select(1, ...), select(2, ...))
      end
    end

    query_mod.get = guarded
  end

  vim.api.nvim_create_user_command('TSQueryFix', function(args)
    run_fix(args.fargs[1], not args.bang)
  end, { nargs = 1, bang = true, desc = 'Fix a broken treesitter parser (use ! to reinstall only)' })
end

--- True while the language has at least one failing query or a repair is running.
---@param lang string
function M.is_broken(lang)
  return repairing[lang] or next(broken[lang] or {}) ~= nil
end

return M
