return {
  'navarasu/onedark.nvim',
  essential = true,
  priority = 1000, -- make sure to load this before all the other start plugins
  config = function()
    require('onedark').setup {
      style = 'darker',
      -- dark, darker, cold, deep, warm, warmer
    }
    require('onedark').load()
  end,
}
