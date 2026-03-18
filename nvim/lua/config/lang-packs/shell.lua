-- .zsh, .sh, .nu coverage

return {
  servers = {
    bashls = {
      filetypes = { 'sh', 'bash', 'zsh' },
    },
    nushell = { mason = false },
  },
  formatters = {
    zsh = { 'shfmt' },
    sh = { 'shfmt' },
    bash = { 'shfmt' },
  },
  linters = {},
  tools = { 'shfmt' },
  treesitter = { 'bash', 'nu' },
}
