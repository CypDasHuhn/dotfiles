return {
  servers = {
    just = {
      on_attach = function(client, bufnr)
        vim.lsp.semantic_tokens.stop(bufnr, client.id)
        client.server_capabilities.semanticTokensProvider = nil
      end,
    },
  },
  tools = {
    'just-lsp',
  },
  treesitter = { 'just' },
}
