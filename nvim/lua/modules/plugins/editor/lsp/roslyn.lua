return {
  'seblyng/roslyn.nvim',
  ft = 'cs',
  dependencies = {
    { 'mason-org/mason.nvim' },
  },
  opts = {
    exe = 'Microsoft.CodeAnalysis.LanguageServer',
    filewatching = true,
    broad_search = true,
    config = {
      settings = {
        ['csharp|inlay_hints'] = {
          csharp_enable_inlay_hints_for_implicit_object_creation = true,
          csharp_enable_inlay_hints_for_implicit_variable_types = true,
          csharp_enable_inlay_hints_for_lambda_parameter_types = true,
          csharp_enable_inlay_hints_for_types = true,
          dotnet_enable_inlay_hints_for_indexer_parameters = true,
          dotnet_enable_inlay_hints_for_literal_parameters = true,
          dotnet_enable_inlay_hints_for_object_creation_parameters = true,
          dotnet_enable_inlay_hints_for_other_parameters = true,
          dotnet_enable_inlay_hints_for_parameters = true,
        },
      },
    },
  },
}
