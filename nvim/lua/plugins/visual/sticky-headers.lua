return {
  'nvim-treesitter/nvim-treesitter-context',
  config = function()
    require('treesitter-context').setup {
      enable = true,
      max_lines = 10, -- How many lines of context
      min_window_height = 0,
      line_numbers = true, -- Show line numbers in context
      multiline_threshold = 1,
      trim_scope = 'outer',
      mode = 'cursor', -- or 'topline'
    }
  end,
}
