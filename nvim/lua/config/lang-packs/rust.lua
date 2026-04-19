return {
  servers = {
    rust_analyzer = { mason = false },
  },
  formatters = {
    rust = { 'rustfmt' },
  },
  linters = {},
  tools = {},
  treesitter = { 'rust' },
}
