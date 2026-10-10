local M = {}

local CACHE_ROOT = vim.fs.joinpath(vim.fn.stdpath 'data', 'kotlin-lsp-server')
local POLL_INTERVAL = 500
local START_TIMEOUT = 120000

local spawned = {}
local notified = {}

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

local function spawn(port)
  if spawned[port] then return true end
  local job = vim.fn.jobstart({
    'kotlin-lsp',
    '--socket',
    '127.0.0.1:' .. port,
    '--multi-client',
    '--data-sharing',
    'none',
    '--log-level',
    'ERROR',
  }, {
    detach = true,
    env = { XDG_CACHE_HOME = CACHE_ROOT },
  })
  if job <= 0 then
    return false
  end
  spawned[port] = true
  return true
end

local function notify_once(key, msg, level)
  if notified[key] then return end
  notified[key] = true
  vim.notify(msg, level)
end

local function wait_for_server(port, on_ready)
  local deadline = vim.uv.now() + START_TIMEOUT
  local function poll()
    if probe(port) then
      on_ready(true)
    elseif vim.uv.now() >= deadline then
      spawned[port] = nil
      on_ready(false)
    else
      vim.defer_fn(poll, POLL_INTERVAL)
    end
  end
  vim.defer_fn(poll, POLL_INTERVAL)
end

function M.root_dir(bufnr, on_dir)
  local markers = (vim.lsp.config.kotlin_lsp or {}).root_markers
  local root = vim.fs.root(bufnr, markers or {}) or vim.uv.cwd()
  local port = port_for(root)

  if probe(port) then
    on_dir(root)
    return
  end

  if not spawn(port) then
    notify_once('spawn:' .. port, 'kotlin-lsp: failed to start (is kotlin-lsp installed?)', vim.log.levels.ERROR)
    return
  end

  notify_once('start:' .. port, 'kotlin-lsp: starting server for ' .. vim.fs.basename(root) .. '...', vim.log.levels.INFO)

  wait_for_server(port, function(ok)
    if ok then
      on_dir(root)
    else
      notify_once(
        'timeout:' .. port,
        ('kotlin-lsp: server for %s did not start within %ds'):format(root, START_TIMEOUT / 1000),
        vim.log.levels.ERROR
      )
    end
  end)
end

function M.connect(dispatchers, config)
  local port = port_for(config.root_dir or vim.uv.cwd())
  return vim.lsp.rpc.connect('127.0.0.1', port)(dispatchers)
end

return M
