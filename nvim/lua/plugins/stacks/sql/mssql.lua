-- Maps project directories to a connection name (a key in mssql.nvim's
-- connections.json), so opening a .sql buffer under one of these directories
-- auto-connects it without going through the connection picker each time.
-- Edit via `:MSSQLEditProjects` or `<leader>mp`.
local projects_file = vim.fs.joinpath(vim.fn.stdpath('config'), 'mssql', 'projects.json')

local function ensure_projects_file()
  if vim.fn.filereadable(projects_file) == 1 then
    return
  end
  vim.fn.mkdir(vim.fs.dirname(projects_file), 'p')
  local default_contents = [=[
{
  "/path/to/project-a": "ConnectionNameFromConnectionsJson",
  "/path/to/project-b": "AnotherConnectionName"
}
]=]
  vim.fn.writefile(vim.split(default_contents, '\n'), projects_file)
end

local function get_project_connections()
  if vim.fn.filereadable(projects_file) == 0 then
    return nil
  end
  local f = io.open(projects_file, 'r')
  if not f then
    return nil
  end
  local content = f:read('*a')
  f:close()
  local ok, json = pcall(vim.json.decode, content)
  if not (ok and type(json) == 'table') then
    vim.notify('mssql projects.json is not valid JSON', vim.log.levels.ERROR)
    return nil
  end
  return json
end

local function edit_projects()
  ensure_projects_file()
  vim.cmd.edit(projects_file)
end

-- Finds the connection name for the longest matching project directory
-- prefix of the given buffer's file path. Using the buffer path (rather
-- than nvim's cwd) means this works regardless of where nvim was launched
-- from or whether you've `cd`'d into the project.
local function find_connection_name_for_buf(buf)
  local projects = get_project_connections()
  if not projects then
    return nil
  end
  local path = vim.api.nvim_buf_get_name(buf)
  if path == '' then
    return nil
  end
  path = vim.fs.normalize(path)
  local best_dir, best_name
  for dir, name in pairs(projects) do
    local normalized = vim.fs.normalize(dir):gsub('/+$', '')
    if path == normalized or path:sub(1, #normalized + 1) == normalized .. '/' then
      if not best_dir or #normalized > #best_dir then
        best_dir, best_name = normalized, name
      end
    end
  end
  return best_name
end

return {
  'Kurren123/mssql.nvim',
  ft = { 'sql' },
  cmd = { 'MSSQL' },
  init = function()
    -- Keep the command/keymap scoped to sql buffers rather than global.
    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('mssql-edit-projects', { clear = true }),
      pattern = 'sql',
      callback = function(args)
        vim.api.nvim_buf_create_user_command(args.buf, 'MSSQLEditProjects', edit_projects, {
          desc = 'Edit the mssql.nvim project -> connection mapping file',
        })
        vim.keymap.set('n', '<leader>mp', edit_projects, {
          buffer = args.buf,
          desc = 'Edit MSSQL project connections',
        })
      end,
    })

    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('mssql-disable-formatting', { clear = true }),
      callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.name == 'mssql_ls' then
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
        end
      end,
    })

    -- Auto-connect newly attached sql buffers if the buffer's file path
    -- matches a project registered in projects.json.
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('mssql-auto-connect', { clear = true }),
      callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if not (client and client.name == 'mssql_ls') then
          return
        end

        local buf = event.buf
        local qm = vim.b[buf].query_manager
        local states = require('mssql.query_manager').states
        if not qm or qm.get_state() ~= states.Disconnected then
          return
        end

        local conn_name = find_connection_name_for_buf(buf)
        if not conn_name then
          return
        end

        -- Matches mssql.nvim's default connections_file location (data_dir
        -- is not overridden in our opts below).
        local connections_file = vim.fs.joinpath(vim.fn.stdpath('data'), 'mssql.nvim', 'connections.json')

        local f = io.open(connections_file, 'r')
        if not f then
          return
        end
        local content = f:read('*a')
        f:close()
        local ok, connections = pcall(vim.json.decode, content)
        if not (ok and connections and connections[conn_name]) then
          vim.notify(
            'mssql: no connection named "' .. conn_name .. '" found in connections.json',
            vim.log.levels.WARN
          )
          return
        end

        require('mssql.utils').try_resume(coroutine.create(function()
          qm.connect_async({ connection = { options = connections[conn_name] } })
        end))
      end,
    })

    -- Results buffers are markdown tables with one row per line. With wide
    -- result sets (many columns) those lines get long, and neovim's default
    -- 'wrap' softwraps them onto multiple screen lines, which breaks the
    -- box-drawing borders render-markdown.nvim draws (it assumes one row =
    -- one screen line). Disable wrap for these buffers so wide rows scroll
    -- horizontally instead of wrapping. mssql.nvim tags its results buffers
    -- with the buffer-local `query_result_info` variable.
    vim.api.nvim_create_autocmd('BufWinEnter', {
      group = vim.api.nvim_create_augroup('mssql-results-nowrap', { clear = true }),
      callback = function(args)
        if vim.b[args.buf].query_result_info then
          vim.wo.wrap = false
          vim.wo.linebreak = false
        end
      end,
    })
  end,
  opts = {
    keymap_prefix = '<leader>m',
    lsp_settings = {
      format = {
        placeCommasBeforeNextStatement = false,
        placeSelectStatementReferencesOnNewLine = false,
        keywordCasing = 'None',
        datatypeCasing = 'None',
        alignColumnDefinitionsInColumns = false,
      },
    },
  },
  config = function(_, opts)
    require('mssql').setup(opts)

    -- mssql.nvim renders query results as a markdown pipe table (rendered
    -- nicely via render-markdown.nvim). It escapes newlines in cell values,
    -- but not literal `|` characters. Columns containing unescaped pipes
    -- (eg. "Zoom Client|Zoom Client for IT Admin|Zoom Workplace") desync the
    -- table's cell count from its header, breaking the markdown parser and
    -- leaving the raw, unrendered pipe text visible. Escape `|` (and any
    -- literal `\`, so our new escapes aren't ambiguous) before mssql.nvim
    -- builds the table.
    local utils = require('mssql.utils')
    local get_rows_async = utils.get_rows_async
    utils.get_rows_async = function(...)
      local rows = get_rows_async(...)
      for _, row in ipairs(rows) do
        for i, value in ipairs(row) do
          row[i] = tostring(value):gsub('\\', '\\\\'):gsub('|', '\\|')
        end
      end
      return rows
    end
  end,
}
