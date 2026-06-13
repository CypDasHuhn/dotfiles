-- Language loader
-- Scans all .lua files in this directory (except init.lua),
-- requires each one, and merges their returned tables into
-- unified config tables for LSP, formatting, linting, etc.
--
-- Each language file should return:
-- {
--   servers = { ... },      -- LSP server configs
--   server_aliases = { ... }, -- LSP server name aliases
--   formatters = { ... },   -- conform.nvim formatters_by_ft
--   linters = { ... },      -- nvim-lint linters_by_ft
--   tools = { ... },        -- extra Mason tools to install
--   treesitter = { ... },   -- treesitter parsers
--   autofold = {            -- treesitter node types to auto-fold on open
--     kotlin = { 'import_list' },
--   },
--   filetypes = {           -- vim.filetype.add args
--     extension = { ... },
--     filename = { ... },
--     pattern = { ... },
--   },
-- }

local M = {
  servers = {},
  server_aliases = {},
  formatters = {},
  linters = {},
  tools = {},
  treesitter = {},
  autofold = {},
  filetypes = { extension = {}, filename = {}, pattern = {} },
}

-- Find this file's directory
local source = debug.getinfo(1, 'S').source:sub(2) -- remove leading @
local dir = vim.fn.fnamemodify(source, ':h')

local files = vim.fn.glob(dir .. '/*.lua', false, true)
for _, file in ipairs(files) do
  local name = vim.fn.fnamemodify(file, ':t:r')
  if name ~= 'init' then
    local ok, lang = pcall(dofile, file)
    if ok and type(lang) == 'table' then
      -- Merge servers
      if lang.servers then
        for k, v in pairs(lang.servers) do
          M.servers[k] = v
        end
      end
      -- Merge server aliases
      if lang.server_aliases then
        for k, v in pairs(lang.server_aliases) do
          M.server_aliases[k] = v
        end
      end
      -- Merge formatters
      if lang.formatters then
        for k, v in pairs(lang.formatters) do
          M.formatters[k] = v
        end
      end
      -- Merge linters
      if lang.linters then
        for k, v in pairs(lang.linters) do
          M.linters[k] = v
        end
      end
      -- Append tools
      if lang.tools then
        vim.list_extend(M.tools, lang.tools)
      end
      -- Append treesitter parsers
      if lang.treesitter then
        vim.list_extend(M.treesitter, lang.treesitter)
      end
      -- Merge autofold node types per filetype
      if lang.autofold then
        for ft, node_types in pairs(lang.autofold) do
          if not M.autofold[ft] then M.autofold[ft] = {} end
          vim.list_extend(M.autofold[ft], node_types)
        end
      end
      -- Merge filetypes
      if lang.filetypes then
        for _, key in ipairs { 'extension', 'filename', 'pattern' } do
          if lang.filetypes[key] then
            for k, v in pairs(lang.filetypes[key]) do
              M.filetypes[key][k] = v
            end
          end
        end
      end
    end
  end
end

vim.filetype.add(M.filetypes)

return M
