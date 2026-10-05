return {
  'lukas-reineke/indent-blankline.nvim',
  main = 'ibl',
  event = { 'BufReadPost', 'BufNewFile' },
  dependencies = {
    'HiPhish/rainbow-delimiters.nvim',
  },
  config = function()
    local hooks = require 'ibl.hooks'
    hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)

    require('ibl').setup {
      debounce = 400,
      viewport_buffer = { min = 30, max = 250 },
      indent = { char = '│' },
      scope = {
        enabled = true,
        injected_languages = false,
        highlight = {
          'RainbowDelimiterRed',
          'RainbowDelimiterYellow',
          'RainbowDelimiterBlue',
          'RainbowDelimiterOrange',
          'RainbowDelimiterGreen',
          'RainbowDelimiterViolet',
          'RainbowDelimiterCyan',
        },
      },
    }
  end,
}
