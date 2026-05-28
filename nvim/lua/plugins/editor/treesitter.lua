local langs = require '.config.lang-packs.init'

local parser_dir = vim.fn.stdpath 'data' .. '/treesitter'

local function unique(list)
  local seen = {}
  local result = {}

  for _, item in ipairs(list or {}) do
    if not seen[item] then
      seen[item] = true
      result[#result + 1] = item
    end
  end

  return result
end

local function parse_version(version)
  local major, minor, patch = tostring(version):match '(%d+)%.(%d+)%.(%d+)'
  if not major then
    return nil
  end

  return { tonumber(major), tonumber(minor), tonumber(patch) }
end

local function version_at_least(version, target)
  if not version then
    return false
  end

  for i = 1, 3 do
    if version[i] ~= target[i] then
      return version[i] > target[i]
    end
  end

  return true
end

return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  event = { 'BufReadPost', 'BufNewFile' },
  init = function()
    vim.opt.runtimepath:prepend(parser_dir)
  end,
  opts = {
    ensure_installed = unique(langs.treesitter),
    auto_install = true,
    parser_install_dir = parser_dir,
    highlight = {
      enable = false,
    },
  },
  config = function(_, opts)
    local install = require 'nvim-treesitter.install'
    local cli_version = parse_version(vim.fn.system 'tree-sitter --version')

    if version_at_least(cli_version, { 0, 25, 0 }) then
      install.ts_generate_args = { 'generate', '--abi', tostring(vim.treesitter.language_version) }
    elseif version_at_least(cli_version, { 0, 20, 3 }) then
      install.ts_generate_args = { 'generate', '--no-bindings', '--abi', tostring(vim.treesitter.language_version) }
    else
      install.ts_generate_args = { 'generate', '--no-bindings' }
    end

    require('nvim-treesitter.configs').setup(opts)
  end,
}
