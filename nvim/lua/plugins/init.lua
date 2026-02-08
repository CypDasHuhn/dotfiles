-- Auto-discover all subdirectories and import them as plugin specs
local source = debug.getinfo(1, 'S').source:sub(2)
local dir = vim.fn.fnamemodify(source, ':h')

local specs = {}
for _, path in ipairs(vim.fn.glob(dir .. '/*', false, true)) do
  if vim.fn.isdirectory(path) == 1 then
    local name = vim.fn.fnamemodify(path, ':t')
    table.insert(specs, { import = 'plugins.' .. name })
  end
end

return specs
