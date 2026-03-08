return {
  'nvim-treesitter/nvim-treesitter',
  event = { 'BufReadPost', 'BufNewFile' },
  build = ':TSUpdate',
  main = 'nvim-treesitter.configs', -- Sets main module to use for opts
  opts = function()
    local langs = require '.config.lang-packs.init'

    return {
      ensure_installed = vim.list_extend(
        { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' },
        langs.treesitter
      ),
      auto_install = true,
      highlight = {
        enable = true,
      },
      indent = { enable = true },
    }
  end,
}
