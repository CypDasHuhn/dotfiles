local check_version = function()
  local verstr = tostring(vim.version())
  if not vim.version.ge then
    vim.health.error(string.format("Neovim out of date: '%s'. Upgrade to latest stable or nightly", verstr))
    return
  end

  if vim.version.ge(vim.version(), '0.10-dev') then
    vim.health.ok(string.format("Neovim version is: '%s'", verstr))
  else
    vim.health.error(string.format("Neovim out of date: '%s'. Upgrade to latest stable or nightly", verstr))
  end
end

local check_external_reqs = function()
  for _, exe in ipairs { 'git', 'make', 'unzip', 'rg' } do
    local is_executable = vim.fn.executable(exe) == 1
    if is_executable then
      vim.health.ok(string.format("Found executable: '%s'", exe))
    else
      vim.health.warn(string.format("Could not find executable: '%s'", exe))
    end
  end

  return true
end

local check_lsp_binaries = function()
  vim.health.start 'LSP servers (mason)'

  local ok_setup, lsp_setup = pcall(require, 'lib.lsp_setup')
  local servers = ok_setup and lsp_setup.mason_servers or nil
  if not servers or vim.tbl_isempty(servers) then
    vim.health.info 'No mason-managed LSP servers configured, or LSP setup has not run yet.'
    return
  end

  local ok_guard, guard = pcall(require, 'lib.lsp-guard')
  local ok_reg, registry = pcall(require, 'mason-registry')

  local package_map = {}
  local ok_mappings, mappings = pcall(require, 'mason-lspconfig.mappings')
  if ok_mappings then
    local ok_map, map = pcall(mappings.get_mason_map)
    if ok_map then
      package_map = map.lspconfig_to_package
    end
  end

  local names = vim.tbl_keys(servers)
  table.sort(names)

  for _, server in ipairs(names) do
    local pkg = package_map[server]
    local healthy = ok_guard and guard.binary_ok(server)
    local installed = ok_reg and pkg and registry.is_installed(pkg)

    if healthy then
      vim.health.ok(string.format("'%s' is executable%s", server, pkg and (" ('" .. pkg .. "')") or ''))
    elseif not ok_reg then
      vim.health.warn(string.format("'%s' is not executable (mason-registry unavailable)", server))
    elseif not pkg then
      vim.health.warn(string.format("'%s' is not executable and is not managed by mason", server))
    elseif not installed then
      vim.health.warn(string.format("'%s' is not installed yet (mason package: '%s')", server, pkg))
    else
      vim.health.error(
        string.format("'%s' is installed ('%s') but its command is not executable. Run :LspRepair %s", server, pkg, server)
      )
    end
  end
end

return {
  check = function()
    vim.health.start 'Rooster Home'

    vim.health.info [[NOTE: Not every warning is a 'must-fix' in `:checkhealth`

  Fix only warnings for plugins and languages you intend to use.
    Mason will give warnings for languages that are not installed.
    You do not need to install, unless you want to use those languages!]]

    local uv = vim.uv or vim.loop
    vim.health.info('System Information: ' .. vim.inspect(uv.os_uname()))

    check_version()
    check_external_reqs()
    check_lsp_binaries()
  end,
}
