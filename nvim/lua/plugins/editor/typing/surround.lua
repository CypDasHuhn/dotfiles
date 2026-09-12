return {
  'kylechui/nvim-surround',
  event = 'VeryLazy',
  init = function()
    vim.g.nvim_surround_no_visual_mappings = true
  end,
  opts = {},
  config = function(_, opts)
    require('nvim-surround').setup(opts)
    local surrounds = {
      { '(', ')' },
      { '[', ']' },
      { '{', '}' },
      { "'", "'" },
      { '"', '"' },
    }
    for _, pair in ipairs(surrounds) do
      vim.keymap.set('x', pair[1], '<Plug>(nvim-surround-visual)' .. pair[1], {
        desc = 'Surround selection with ' .. pair[1] .. pair[2],
      })
    end
  end,
}
