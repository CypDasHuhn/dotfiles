return {
  servers = {
    bashls = {
      filetypes = { 'sh', 'bash', 'zsh' },
    },
  },
  formatters = {
    zsh = { 'shfmt' },
    sh = { 'shfmt' },
    bash = { 'shfmt' },
  },
  linters = {},
  tools = { 'shfmt' },
  treesitter = { 'bash' },
}
