local source = debug.getinfo(1, 'S').source:sub(2)
local root = vim.fn.fnamemodify(source, ':h')

local function module_name(path)
  return vim.fn.fnamemodify(path, ':t:r')
end

local function load_recursive(dir)
  for _, path in ipairs(vim.fn.glob(dir .. '/*', false, true)) do
    if vim.fn.isdirectory(path) == 1 then
      load_recursive(path)
    elseif path:match('%.lua$') and module_name(path) ~= 'init' then
      dofile(path)
    end
  end
end

load_recursive(root)
