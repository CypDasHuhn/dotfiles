return {
  'GustavEikaas/easy-dotnet.nvim',
  dependencies = { 'nvim-lua/plenary.nvim', 'nvim-telescope/telescope.nvim' },
  ft = { 'cs', 'fsproj', 'csproj', 'sln' },
  config = function()
    require('easy-dotnet').setup {
      lsp = {
        enabled = true,
        auto_refresh_codelens = false,
        config = {
          settings = {
            ["csharp|inlay_hints"] = {
              csharp_enable_inlay_hints_for_implicit_object_creation = true,
              csharp_enable_inlay_hints_for_implicit_variable_types = true,
              csharp_enable_inlay_hints_for_lambda_parameter_types = true,
              csharp_enable_inlay_hints_for_types = true,
              dotnet_enable_inlay_hints_for_parameters = true,
            },
            ["csharp|code_lens"] = {
              dotnet_enable_references_code_lens = true,
            },
          },
        },
      },
    }

    local csharp_codelens = require 'config.dotnet.codelens'
    local easy_dotnet = vim.lsp.config.easy_dotnet
    if easy_dotnet and easy_dotnet.on_attach then
      local original_on_attach = easy_dotnet.on_attach
      easy_dotnet.on_attach = function(client, bufnr)
        original_on_attach(client, bufnr)
        csharp_codelens.on_attach(client, bufnr)
      end
    end
  end,
}
