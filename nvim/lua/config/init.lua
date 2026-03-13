local source = debug.getinfo(1, 'S').source:sub(2)
local root = vim.fn.fnamemodify(source, ':h')

local function module_name(path)
  return vim.fn.fnamemodify(path, ':t:r')
end

local files = vim.fn.glob(root .. '/*.lua', false, true)

for _, file in ipairs(files) do
  local name = module_name(file)
  if name ~= 'init' then
    dofile(file)
  end
end
