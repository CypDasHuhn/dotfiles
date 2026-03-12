local source = debug.getinfo(1, 'S').source:sub(2)
local root = vim.fn.fnamemodify(source, ':h')

local function module_name(path)
  return vim.fn.fnamemodify(path, ':t:r')
end

local priorities = {
  settings = 1,
}

local files = vim.fn.glob(root .. '/*.lua', false, true)
table.sort(files, function(a, b)
  local a_name = module_name(a)
  local b_name = module_name(b)
  local a_priority = priorities[a_name] or 50
  local b_priority = priorities[b_name] or 50

  if a_priority == b_priority then
    return a_name < b_name
  end

  return a_priority < b_priority
end)

for _, file in ipairs(files) do
  local name = module_name(file)
  if name ~= 'init' then
    dofile(file)
  end
end
