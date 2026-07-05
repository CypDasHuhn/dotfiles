return {
  servers = {
    just = {
      on_attach = function(client, bufnr)
        vim.lsp.semantic_tokens.enable(false, bufnr, client.id)
        client.server_capabilities.semanticTokensProvider = nil
      end,
    },
  },
  tools = {
    'just-lsp',
  },
  treesitter = { 'just' },
  filetypes = {
    filename = {
      justfile = 'just',
    },
    pattern = {
      ['.*%.justfile'] = 'just',
    },
  },
}
