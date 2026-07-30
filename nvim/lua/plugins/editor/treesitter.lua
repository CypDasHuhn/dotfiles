local langs = require '.config.lang-packs.init'

local install_dir = vim.fn.stdpath 'data' .. '/site'

return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  lazy = false,
  config = function()
    local ensure_installed = {}
    for _, lang in ipairs(langs.treesitter or {}) do
      ensure_installed[lang] = true
    end

    local ts = require 'nvim-treesitter'
    ts.setup {
      install_dir = install_dir,
    }

    local languages = vim.tbl_keys(ensure_installed)
    if #languages > 0 then
      local installed = {}
      for _, lang in ipairs(ts.get_installed()) do
        installed[lang] = true
      end

      local missing = vim.tbl_filter(function(lang)
        return not installed[lang]
      end, languages)

      if #missing > 0 then
        ts.install(missing)
      end
    end
  end,
}
