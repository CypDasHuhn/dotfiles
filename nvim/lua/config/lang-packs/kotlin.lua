return {
  servers = {
    kotlin_lsp = {
      mason = false,
      single_file_support = false,
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
