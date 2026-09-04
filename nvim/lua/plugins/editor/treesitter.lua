local langs = require '.config.lang-packs.init'

local install_dir = vim.fn.stdpath 'data' .. '/site'

return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  lazy = false,
  dependencies = {
    'HiPhish/rainbow-delimiters.nvim',
  },
  config = function()
    require('nvim-treesitter').setup {
      install_dir = install_dir,
    }
    if langs.treesitter and #langs.treesitter > 0 then
      require('nvim-treesitter').install(langs.treesitter)
    end
  end,
}
