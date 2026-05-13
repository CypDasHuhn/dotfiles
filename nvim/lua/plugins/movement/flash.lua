return {
  'folke/flash.nvim',
  essential = true,
  enabled = true,
  event = 'VeryLazy',
  ---@type Flash.Config
  opts = {},
  config = function(_, opts)
    require('flash').setup(opts)
    local function set_hl()
      vim.api.nvim_set_hl(0, 'FlashLabelBackward', { fg = '#ff9e64', bold = true, nocombine = true })
    end
    set_hl()
    vim.api.nvim_create_autocmd('ColorScheme', { callback = set_hl })
  end,
  keys = {
    {
      'o',
      mode = { 'n', 'x', 'o' },
      function()
        require('flash').jump()
      end,
      desc = 'Flash',
    },
    {
      'O',
      mode = { 'n', 'x', 'o' },
      function()
        require('flash').treesitter()
      end,
      desc = 'Flash Treesitter',
    },
    {
      '<c-o>',
      mode = { 'c' },
      function()
        require('flash').toggle()
      end,
      desc = 'Toggle Flash Search',
    },
  },
}
