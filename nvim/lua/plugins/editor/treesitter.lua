local langs = require '.config.lang-packs.init'

local parser_dir = vim.fn.stdpath 'data' .. '/treesitter'

return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  event = { 'BufReadPost', 'BufNewFile' },
  init = function()
    vim.opt.runtimepath:prepend(parser_dir)
  end,
  opts = function()
    local ensure_installed = {}
    for _, lang in ipairs(langs.treesitter or {}) do
      ensure_installed[lang] = true
    end
    return {
      parser_install_dir = parser_dir,
      ensure_installed = vim.tbl_keys(ensure_installed),
      auto_install = true,
    }
  end,
  config = function(_, opts)
    require('nvim-treesitter').setup(opts)
  end,
}
