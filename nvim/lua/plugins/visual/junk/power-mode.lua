return {
  'axsaucedo/neovim-power-mode',
  cmd = {
    'PowerModeToggle',
    'PowerModeEnable',
    'PowerModeDisable',
    'PowerModeStyle',
    'PowerModeShake',
    'PowerModeFireWall',
    'PowerModeInterrupt',
    'PowerModeCancel',
    'PowerModeStatus',
  },
  config = function()
    require('power-mode').setup {
      auto_enable = false,
      particles = { preset = 'stars' },
      shake = { mode = 'scroll' },
    }
  end,
}
