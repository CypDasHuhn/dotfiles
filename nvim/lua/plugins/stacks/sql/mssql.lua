return {
  'Kurren123/mssql.nvim',
  ft = { 'sql' },
  cmd = { 'MSSQL' },
  init = function()
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
