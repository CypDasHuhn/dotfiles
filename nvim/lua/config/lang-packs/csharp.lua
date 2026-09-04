return {
  servers = {
    -- Note: roslyn must be manually configured, not installed via Mason
    -- easy-dotnet.nvim helps manage it but we need to set it up
  },
  treesitter = { 'c_sharp', 'razor' },
  autofold = {
    cs = { 'using_directive' },
  },
  tools = {
    'csharpier', -- C# formatter
    'html-lsp', -- Razor markup support via vscode-html-language-server
    'netcoredbg', -- .NET debugger
  },
}
