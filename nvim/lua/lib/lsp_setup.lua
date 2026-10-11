local guard = require 'lib.lsp-guard'

local uv = vim.uv

local M = {}

M.mason_servers = {}

local function resolve_cmd(cmd)
  if type(cmd) ~= 'table' or type(cmd[1]) ~= 'string' then
    return cmd
  end

  local exe = vim.fn.exepath(cmd[1])
  if exe == '' then
    return cmd
  end

  local real = uv.fs_realpath(exe)
  if not real or real == exe then
    return cmd
  end

  local resolved = vim.deepcopy(cmd)
  resolved[1] = real
  return resolved
end

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

function M.apply_lspmux(server_name, config)
  if config.lspmux == false then return config end
  if vim.fn.executable 'lspmux' ~= 1 then return config end

  local cmd = config.cmd
  if not cmd then
    local defaults = vim.lsp.config[server_name]
    cmd = defaults and defaults.cmd
  end
  if not cmd or type(cmd) ~= 'table' then return config end

  local bin = vim.fn.exepath(cmd[1])
  if bin == '' then return config end

  local wrapped = vim.deepcopy(config)
  local lspmux_cmd = { 'lspmux', 'client', '--server-path', bin }
  for i = 2, #cmd do
    lspmux_cmd[#lspmux_cmd + 1] = cmd[i]
  end
  wrapped.cmd = lspmux_cmd
  return wrapped
end

local function setup_server(server_name, server, use_lspmux)
  local resolved = vim.deepcopy(server or {})
  resolved.mason = nil

  local original_exit = resolved.on_exit
  resolved.on_exit = function(code, signal, client_id)
    if original_exit then
      original_exit(code, signal, client_id)
    end
    guard.on_exit(server_name, code)
  end

  local cmd = resolved.cmd
  if not cmd then
    local defaults = vim.lsp.config[server_name]
    cmd = defaults and defaults.cmd
  end
  local resolved_cmd = resolve_cmd(cmd)
  if resolved_cmd ~= cmd then
    resolved.cmd = resolved_cmd
  end

  if use_lspmux then
    resolved = M.apply_lspmux(server_name, resolved)
  end
  resolved.lspmux = nil
  vim.lsp.config(server_name, resolved)
  vim.lsp.enable(server_name)
end

function M.setup(opts)
  opts = opts or {}

  vim.lsp.config('*', { flags = { debounce_text_changes = 500 } })

  require('mason').setup {
    registries = opts.mason_registries or {
      'github:mason-org/mason-registry',
      'github:Crashdummyy/mason-registry',
    },
  }

  local servers = normalize_servers(opts.servers or {}, opts.server_aliases or {})
  local mason_servers, manual_servers = split_servers(servers)
  M.mason_servers = mason_servers

  require('mason-lspconfig').setup {
    ensure_installed = vim.tbl_keys(mason_servers),
    automatic_enable = false,
  }

  for server_name, server in pairs(mason_servers) do
    setup_server(server_name, server, opts.lspmux)
  end

  for server_name, server in pairs(manual_servers) do
    setup_server(server_name, server, opts.lspmux)
  end

  local tools = vim.deepcopy(opts.tools or {})
  require('mason-tool-installer').setup { ensure_installed = tools }

  guard.setup {
    servers = vim.tbl_keys(mason_servers),
    auto_reinstall = opts.auto_reinstall,
  }

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
