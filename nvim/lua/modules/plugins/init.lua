-- Auto-discover all subdirectories (recursively) and import them as plugin specs
local source = debug.getinfo(1, 'S').source:sub(2)
local dir = vim.fn.fnamemodify(source, ':h')

local specs = {}
for _, path in ipairs(vim.fn.glob(dir .. '/**', false, true)) do
  if vim.fn.isdirectory(path) == 1 then
    local relpath = path:sub(#dir + 2) -- strip base dir + separator
    local modpath = 'modules.plugins.' .. relpath:gsub('[/\\]', '.')
    table.insert(specs, { import = modpath })
  end
end

return specs
