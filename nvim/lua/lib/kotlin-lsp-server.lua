local M = {}

local CACHE_ROOT = vim.fs.joinpath(vim.fn.stdpath 'data', 'kotlin-lsp-server')

local function port_for(root)
  local seed = tonumber(vim.fn.sha256(root or ''):sub(1, 8), 16) or 0
  return 13000 + seed % 20000
end

local function probe(port)
  local ok, ch = pcall(vim.fn.sockconnect, 'tcp', '127.0.0.1:' .. port)
  if ok and ch and ch ~= 0 then
    pcall(vim.fn.chanclose, ch)
    return true
  end
  return false
end

local function ensure_server(port)
  if probe(port) then return true end
  vim.fn.jobstart({
    'kotlin-lsp',
    '--socket',
    tostring(port),
    '--multi-client',
    '--data-sharing',
    'none',
    '--log-level',
    'ERROR',
  }, {
    detach = true,
    env = { XDG_CACHE_HOME = CACHE_ROOT },
  })
  return vim.wait(90000, function()
    return probe(port)
  end, 500)
end

function M.connect(dispatchers, config)
  local port = port_for(config.root_dir or vim.uv.cwd())
  if ensure_server(port) then
    if vim.fn.has 'nvim-0.12' == 1 then
      return vim.lsp.rpc.connect('127.0.0.1', port)(dispatchers)
    end
    return vim.lsp.rpc.connect('127.0.0.1', port, dispatchers)
  end
  return nil, ('kotlin-lsp broker: server on port %d did not come up in time'):format(port)
end

return M.connect
