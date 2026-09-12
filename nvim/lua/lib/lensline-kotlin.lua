local M = {
  name = 'detekt',
  event = { 'LspAttach', 'BufWritePost' },
}

local SHORTEN = {
  CyclomaticComplexMethod = 'CC',
  LongMethod = 'LM',
  LongParameterList = 'LPL',
  LargeClass = 'LC',
  ComplexConditions = 'CC',
  TooManyFunctions = 'TMF',
}

local cache = {}

local function unescape(text)
  return (tostring(text)
    :gsub('&lt;', '<')
    :gsub('&gt;', '>')
    :gsub('&quot;', '"')
    :gsub('&apos;', "'")
    :gsub('&#39;', "'")
    :gsub('&amp;', '&'))
end

local function find_project_config(path)
  local dir = vim.fs.dirname(path)
  while dir and dir ~= vim.fs.dirname(dir) do
    local candidate = vim.fs.joinpath(dir, 'config', 'detekt', 'detekt.yml')
    if vim.fn.filereadable(candidate) == 1 then return candidate end
    dir = vim.fs.dirname(dir)
  end
  return nil
end

local function format(list)
  local parts = {}
  for _, issue in ipairs(list) do
    parts[#parts + 1] = issue.rule .. (issue.metric and ' ' .. issue.metric or '')
  end
  return '󱆃 ' .. table.concat(parts, ', ')
end

local function emit(callback, line, issues)
  callback(issues and #issues > 0 and { line = line, text = format(issues), highlight = 'WarningMsg' } or nil)
end

local function parse_report(xml_path, on_done)
  local xml = table.concat(vim.fn.readfile(xml_path), '\n')
  vim.fn.delete(xml_path)
  local by_line = {}
  for tag in xml:gmatch '<error.-/>' do
    local source = tag:match 'source="([^"]+)"'
    local line_no = tonumber(tag:match 'line="(%d+)"')
    if source and line_no then
      local message = unescape(tag:match 'message="([^"]*)"' or '')
      local metric = message:match 'complexity (%d+)'
      by_line[line_no] = by_line[line_no] or {}
      table.insert(by_line[line_no], { rule = SHORTEN[source] or source, metric = metric })
    end
  end
  on_done(by_line)
end

local pending = {}

local function deliver(path, by_line)
  cache[path] = { mtime = vim.fn.getftime(path), by_line = by_line }
  local waiting = pending[path]
  pending[path] = nil
  for _, cb in ipairs(waiting or {}) do
    cb()
  end
end

function M.refresh(path, on_done)
  if pending[path] then
    pending[path][#pending[path] + 1] = on_done
    return
  end
  pending[path] = { on_done }
  local out = vim.fn.tempname() .. '.xml'
  local args = { 'detekt', '--input', path, '--report', 'xml:' .. out }
  local project_config = find_project_config(path)
  if project_config then
    vim.list_extend(args, { '--build-upon-default-config', '--config', project_config })
  end
  vim.system(args, { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 and vim.fn.filereadable(out) ~= 1 then
        deliver(path, {})
        return
      end
      parse_report(out, function(by_line)
        deliver(path, by_line)
      end)
    end)
  end)
end

M.handler = function(bufnr, func_info, _provider_config, callback)
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == '' or (vim.bo[bufnr].filetype ~= 'kotlin' and not path:match '%.ktw?s$') then
    callback(nil)
    return
  end
  if not vim.fn.executable 'detekt' then
    callback(nil)
    return
  end

  local cached = cache[path]
  local by_line = cached and cached.mtime == vim.fn.getftime(path) and cached.by_line
  if by_line then
    emit(callback, func_info.line, by_line[func_info.line])
    return
  end

  M.refresh(path, function()
    emit(callback, func_info.line, cache[path].by_line[func_info.line])
  end)
end

return M
