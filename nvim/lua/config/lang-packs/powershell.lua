return {
  servers = {
    powershell_es = {
      bundle_path = vim.fn.stdpath 'data' .. '/mason/packages/powershell-editor-services',
    },
  },
  treesitter = { 'powershell' },
}
