return {
  'Kurren123/mssql.nvim',
  ft = { 'sql' },
  cmd = { 'MSSQL' },
  init = function()
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('mssql-disable-formatting', { clear = true }),
      callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.name == 'mssql_ls' then
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
        end
      end,
    })
  end,
  opts = {
    keymap_prefix = '<leader>m',
    lsp_settings = {
      format = {
        placeCommasBeforeNextStatement = false,
        placeSelectStatementReferencesOnNewLine = false,
        keywordCasing = 'None',
        datatypeCasing = 'None',
        alignColumnDefinitionsInColumns = false,
      },
    },
  },
}
