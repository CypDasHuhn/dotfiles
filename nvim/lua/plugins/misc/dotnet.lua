return {
  "GustavEikaas/easy-dotnet.nvim",
  dependencies = { "nvim-lua/plenary.nvim", 'nvim-telescope/telescope.nvim', },
  config = function()
    require("easy-dotnet").setup({
      -- Use Roslyn LSP (default), not OmniSharp
      lsp = "roslyn",
    })
  end
}
