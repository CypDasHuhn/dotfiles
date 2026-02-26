return {
  'xentropic-dev/explorer.dotnet.nvim',
  config = function()
    require('dotnet_explorer').setup {
      renderer = {
        width = 60,
        side = 'right',
      },
    }
  end,
  keys = {
    { '<leader>se', '<cmd>ToggleSolutionExplorer<cr>', desc = 'Toggle Solution Explorer' },
  },
}
