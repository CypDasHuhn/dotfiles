return {
  servers = {
    kotlin_lsp = {
      mason = false,
      single_file_support = false,
      cmd = {
        'kotlin-lsp',
        '--stdio',
        '--system-path',
        vim.fn.stdpath 'data' .. '/kotlin-lsp',
      },
      on_attach = function(client)
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
      end,
    },
  },
  formatters = {
    kotlin = { 'ktlint' },
  },
  linters = {
    kotlin = { 'ktlint' },
  },
  tools = {
    'ktlint',
  },
  treesitter = { 'kotlin' },
  autofold = {
    kotlin = { 'import_list' },
  },
}
