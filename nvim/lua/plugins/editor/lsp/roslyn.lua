-- Roslyn LSP setup (separate from Mason)
-- Roslyn is installed via easy-dotnet.nvim using :Dotnet bootstrap
return {
  'seblj/roslyn.nvim',
  ft = 'cs',
  opts = {
    config = {
      -- Broadcast blink.cmp capabilities
      capabilities = require('blink.cmp').get_lsp_capabilities(),
      -- Settings for Roslyn
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
