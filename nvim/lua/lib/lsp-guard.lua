local M = {}

local attempted = {}
local attached = {}

local function notify(msg, level)
  vim.schedule(function()
    vim.notify(msg, level or vim.log.levels.INFO, { title = 'lsp-repair' })
  end)
end

local function registry()
  local ok, mod = pcall(require, 'mason-registry')
  return ok and mod or nil
end

local function package_for(server)
  local ok, mappings = pcall(require, 'mason-lspconfig.mappings')
  if not ok then
    return nil
  end
  local ok_map, map = pcall(mappings.get_mason_map)
  if not ok_map then
    return nil
  end
  return map.lspconfig_to_package[server]
end

function M.binary_ok(server)
  local ok, config = pcall(function()
    return vim.lsp.config[server]
  end)
  local cmd = ok and config and config.cmd
  if type(cmd) ~= 'table' or type(cmd[1]) ~= 'string' then
    return true
  end
  return vim.fn.executable(cmd[1]) == 1
end

function M.reinstall(server, reason, force)
  local pkg_name = package_for(server)
  if not pkg_name then
    return false
  end
  if attempted[server] and not force then
    return false
  end
  local reg = registry()
  if not reg then
    return false
  end
  local ok, pkg = pcall(reg.get_package, pkg_name)
  if not ok or not pkg then
    return false
  end

  attempted[server] = true
  notify(
    string.format('Reinstalling %s (%s)%s', server, pkg_name, reason and (': ' .. reason) or ''),
    vim.log.levels.WARN
  )

  pkg:install({ force = true }, vim.schedule_wrap(function(success, err)
    if success then
      notify(
        string.format('Reinstalled %s. Restart the client with <leader>glr if it is still down.', server),
        vim.log.levels.INFO
      )
    else
      notify(string.format('Reinstall of %s failed: %s', server, tostring(err)), vim.log.levels.ERROR)
    end
  end))

  return true
end

function M.on_exit(server, code)
  if code == 0 or code == nil then
    return
  end
  if vim.v.exiting ~= 0 then
    return
  end
  if attached[server] or not package_for(server) then
    return
  end
  vim.schedule(function()
    M.reinstall(server, 'the client exited during startup')
  end)
end

function M.broken(servers)
  local list = {}
  for _, server in ipairs(servers) do
    if package_for(server) and not M.binary_ok(server) then
      list[#list + 1] = server
    end
  end
  return list
end

function M.setup(opts)
  opts = opts or {}
  M.auto = opts.auto_reinstall ~= false

  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('lsp-repair-attach', { clear = true }),
    callback = function(event)
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client then
        attached[client.name] = true
      end
    end,
  })

  if M.auto then
    vim.schedule(function()
      local reg = registry()
      if not reg then
        return
      end
      for _, server in ipairs(opts.servers or {}) do
        local pkg_name = package_for(server)
        if pkg_name and reg.is_installed(pkg_name) and not M.binary_ok(server) then
          M.reinstall(server, 'the mason package is installed but its binary is missing')
        end
      end
    end)
  end

  vim.api.nvim_create_user_command('LspRepair', function(args)
    local requested = args.fargs
    if #requested > 0 then
      for _, server in ipairs(requested) do
        if not M.reinstall(server, 'requested through :LspRepair', true) then
          notify(string.format('Cannot repair %s: it is not a mason-managed LSP server.', server), vim.log.levels.WARN)
        end
      end
      return
    end

    local broken = M.broken(opts.servers or {})
    if #broken == 0 then
      notify('No broken LSP servers detected.', vim.log.levels.INFO)
      return
    end

    for _, server in ipairs(broken) do
      M.reinstall(server, 'the mason package is installed but its binary is missing')
    end
  end, { nargs = '*', desc = 'Reinstall LSP servers whose binary is missing or broken' })
end

return M
