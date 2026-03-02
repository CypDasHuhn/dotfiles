return {
  'wfxr/minimap.vim',
  lazy = false,
  init = function()
    vim.g.minimap_auto_start = 1
    vim.g.minimap_auto_start_win_enter = 1
  end,
  keys = {
    { '<leader>tm', '<cmd>MinimapToggle<CR>', desc = 'Toggle Minimap' },
  },
}
