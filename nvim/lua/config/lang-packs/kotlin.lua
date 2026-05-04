return {
  servers = {
    kotlin_lsp = {
      mason = false,
      single_file_support = false,
      cmd_env = {
        JDK_JAVA_OPTIONS = '-Djava.awt.headless=true',
      },
      init_options = {
        storagePath = vim.fn.stdpath 'data' .. '/kotlin-lsp',
      },
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
}
