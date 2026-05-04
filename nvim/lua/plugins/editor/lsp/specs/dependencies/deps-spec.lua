local root = vim.fn.stdpath 'config' .. '/lua/config/lsp/dependencies'

local function normalize(path)
  return (path or ''):gsub('\\', '/')
end

local function module_from_path(path)
  local normalized_root = normalize(root)
  local normalized_path = normalize(path)
  local rel = normalized_path:sub(#normalized_root + 2)
  rel = rel:gsub('%.lua$', '')
  rel = rel:gsub('/', '.')
  return 'config.lsp.dependencies.' .. rel
end

local function is_list(value)
  if type(value) ~= 'table' then
    return false
  end
  if type(vim.islist) == 'function' then
    return vim.islist(value)
  end
  if vim.tbl_islist then
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

local dependencies = {}
local fields = {}

local files = vim.fn.glob(root .. '/*.lua', false, true)
table.sort(files)

for _, file in ipairs(files) do
  local normalized = normalize(file)
  if not normalized:match('/init%.lua$') then
    local ok, fragment = pcall(require, module_from_path(normalized))
    if ok and type(fragment) == 'table' then
      if is_list(fragment.dependencies) then
        vim.list_extend(dependencies, fragment.dependencies)
      end
      if type(fragment.fields) == 'table' then
        fields = vim.tbl_deep_extend('force', fields, fragment.fields)
      end
    end
  end
end

return {
  'neovim/nvim-lspconfig',
  dependencies = dependencies,
  opts = function(_, opts)
    for key, value in pairs(fields) do
      opts[key] = vim.deepcopy(value)
    end
  end,
}
