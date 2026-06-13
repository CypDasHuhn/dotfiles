local langs = require '.config.lang-packs.init'

local parser_dir = vim.fn.stdpath 'data' .. '/treesitter'

return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  event = { 'BufReadPost', 'BufNewFile' },
  init = function()
    vim.opt.runtimepath:prepend(parser_dir)
  end,
  opts = {
    install_dir = parser_dir,
  },
  config = function(_, opts)
    require('nvim-treesitter.config').setup(opts)

    local install = require 'nvim-treesitter.install'

    local ensure_installed = {}
    for _, lang in ipairs(langs.treesitter or {}) do
      ensure_installed[lang] = true
    end
    local languages = vim.tbl_keys(ensure_installed)

    if #languages > 0 then
      install.install(languages)
    end

    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('TSEnsureInstalled', { clear = true }),
      callback = function(args)
        if langs.treesitter and vim.list_contains(langs.treesitter, vim.bo[args.buf].filetype) then
          install.install(vim.bo[args.buf].filetype)
        end
      end,
    })
  end,
}
