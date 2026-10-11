return {
  'MeanderingProgrammer/render-markdown.nvim',
  enabled = true,
  event = 'VeryLazy',
  dependencies = { 'nvim-mini/mini.nvim' },
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {
    render_modes = true,
    latex = { enabled = false },
  },
}
