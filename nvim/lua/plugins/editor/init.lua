-- Editor plugins
local source = debug.getinfo(1, 'S').source:sub(2)
local dir = vim.fn.fnamemodify(source, ':h')

local specs = {}

-- Load flat .lua files in this directory
for _, file in ipairs(vim.fn.glob(dir .. '/*.lua', false, true)) do
  local name = vim.fn.fnamemodify(file, ':t:r')
  if name ~= 'init' then
    local ok, plugin_spec = pcall(require, 'plugins.editor.' .. name)
    if ok then
      table.insert(specs, plugin_spec)
    end
  end
end

-- Load first-level subdirectories (like lsp/)
for _, path in ipairs(vim.fn.glob(dir .. '/*', false, true)) do
  if vim.fn.isdirectory(path) == 1 then
    local name = vim.fn.fnamemodify(path, ':t')
    table.insert(specs, { import = 'plugins.editor.' .. name })
  end
end

return specs
