local config_path = vim.uv.fs_realpath(vim.fn.stdpath('config')) or vim.fn.stdpath('config')
local machine_path = vim.fn.fnamemodify(config_path, ':h') .. '/.machine.local.lua'
local ok, machine = pcall(dofile, machine_path)

if ok and type(machine) == 'table' then
  return machine.nvim or {}
end

return {}
