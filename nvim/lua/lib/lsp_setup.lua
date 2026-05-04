local M = {}

local function normalize_servers(server_map, aliases)
  local normalized = {}

  for name, config in pairs(server_map or {}) do
    normalized[aliases[name] or name] = config
  end

  return normalized
end

local function split_servers(server_map)
  local mason_servers = {}
  local manual_servers = {}

  for name, config in pairs(server_map or {}) do
    if config and config.mason == false then
      manual_servers[name] = config
    else
      mason_servers[name] = config
    end
  end

  return mason_servers, manual_servers
end

local function setup_server(server_name, server)
  local resolved = vim.deepcopy(server or {})
  resolved.mason = nil
  vim.lsp.config(server_name, resolved)
  vim.lsp.enable(server_name)
end

function M.setup(opts)
  opts = opts or {}

  require('mason').setup {
    registries = opts.mason_registries or {
      'github:mason-org/mason-registry',
      'github:Crashdummyy/mason-registry',
    },
  }

  vim.lsp.config('*', {
    capabilities = require('blink.cmp').get_lsp_capabilities(),
  })

  local servers = normalize_servers(opts.servers or {}, opts.server_aliases or {})
  local mason_servers, manual_servers = split_servers(servers)

  require('mason-lspconfig').setup {
    ensure_installed = vim.tbl_keys(mason_servers),
    automatic_enable = false,
  }

  for server_name, server in pairs(mason_servers) do
    setup_server(server_name, server)
  end

  for server_name, server in pairs(manual_servers) do
    setup_server(server_name, server)
  end

  local tools = vim.deepcopy(opts.tools or {})
  require('mason-tool-installer').setup { ensure_installed = tools }

  if opts.diagnostics then
    vim.diagnostic.config(opts.diagnostics)
  end

  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
    callback = function(event)
      for _, hook in ipairs(opts.on_attach_hooks or {}) do
        hook(event)
      end
    end,
  })
end

return M
