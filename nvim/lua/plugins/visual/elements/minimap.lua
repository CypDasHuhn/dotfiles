local autoStart = false
local minimap = {
  'wfxr/minimap.vim',
  lazy = true,
  keys = {
    { '<leader>tm', '<cmd>MinimapToggle<CR>', desc = 'Toggle Minimap' },
  },
}

-- region Autostart
if autoStart then
  minimap.init = function()
    vim.g.minimap_auto_start = 1
    vim.g.minimap_auto_start_win_enter = 1
  end
end
-- endregion

return minimap
