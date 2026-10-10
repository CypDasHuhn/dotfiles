local kotlin_lsp = require 'lib.kotlin-lsp-server'

return {
  servers = {
    kotlin_lsp = {
      mason = false,
      single_file_support = false,
      cmd = kotlin_lsp.connect,
      root_dir = kotlin_lsp.root_dir,
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
    'detekt',
  },
  treesitter = { 'kotlin' },
  autofold = {
    kotlin = { 'import_list' },
  },
}
