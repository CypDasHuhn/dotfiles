return {
  servers = {
    --[[
    kotlin_lsp = {
      mason = false,
      single_file_support = false,
      cmd = { 'kotlin-lsp-nvim', '--stdio' },
      init_options = {
        storagePath = vim.fn.stdpath 'data' .. '/kotlin-lsp',
      },
    },
    --]]
    kotlin_language_server = {
      mason = false,
      cmd = { 'kotlin-language-server-nvim' },
      on_attach = function(client)
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
        client.server_capabilities.documentHighlightProvider = false
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
