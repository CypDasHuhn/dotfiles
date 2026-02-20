return {
  servers = {
    -- Note: roslyn must be manually configured, not installed via Mason
    -- easy-dotnet.nvim helps manage it but we need to set it up
  },
  treesitter = { 'c_sharp' },
  tools = {
    'csharpier', -- C# formatter
    'netcoredbg', -- .NET debugger
  },
}
