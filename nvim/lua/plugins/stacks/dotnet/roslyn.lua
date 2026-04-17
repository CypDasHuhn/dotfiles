-- Roslyn LSP setup (separate from Mason)
-- Roslyn is installed via easy-dotnet.nvim using :Dotnet bootstrap
return {
  'seblj/roslyn.nvim',
  enabled = false,
  ft = 'cs',
  -- easy-dotnet ships and manages the Roslyn-backed C# LSP already.
  -- Keeping roslyn.nvim enabled here causes a second client config that
  -- fails on Windows unless a separate roslyn binary is installed.
}
