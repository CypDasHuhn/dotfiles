-- Auto-discover all plugin spec files under this directory (recursively).
-- This removes the need for per-folder init.lua files.
local source = debug.getinfo(1, 'S').source:sub(2)
local root = vim.fn.fnamemodify(source, ':h')

local function normalize(path)
  return (path or ''):gsub('\\', '/')
end

local function module_from_path(path)
  local normalized_root = normalize(root)
  local normalized_path = normalize(path)
  local rel = normalized_path:sub(#normalized_root + 2)
  rel = rel:gsub('%.lua$', '')
  rel = rel:gsub('/', '.')
  return 'plugins.' .. rel
end

local specs = {}
local files = vim.fn.glob(root .. '/**/*.lua', false, true)
table.sort(files)

local function is_list(value)
  if type(value) ~= 'table' then
    return false
  end
  if type(vim.islist) == 'function' then
    return vim.islist(value)
  end
  if vim.tbl_islist then
    -- Avoid calling deprecated APIs when possible; keep fallback for older versions.
    return vim.tbl_islist(value)
  end
  local count = 0
  for k, _ in pairs(value) do
    if type(k) ~= 'number' or k <= 0 or k % 1 ~= 0 then
      return false
    end
    count = count + 1
  end
  return count == #value
end

for _, file in ipairs(files) do
  local normalized = normalize(file)
  if not normalized:match('/init%.lua$') then
    local ok, plugin_spec = pcall(require, module_from_path(normalized))
    if ok and plugin_spec then
      if is_list(plugin_spec) then
        vim.list_extend(specs, plugin_spec)
      else
        table.insert(specs, plugin_spec)
      end
    end
  end
end

return specs
