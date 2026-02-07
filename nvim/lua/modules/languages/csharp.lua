return {
  -- Roslyn LSP is handled by seblyng/roslyn.nvim plugin, not via standard lspconfig
  servers = {},

  formatters = {
    cs = { 'csharpier' },
  },

  linters = {},

  tools = {
    'csharpier',
    'roslyn',
  },

  treesitter = {
    'c_sharp',
  },
}
