local langs = require '.config.lang-packs.init'

return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  main = 'nvim-treesitter.configs', -- Sets main module to use for opts
  opts = {
    ensure_installed = vim.list_extend(
      { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' },
      langs.treesitter
    ),
    auto_install = true,
    highlight = {
      enable = true,
    },
    indent = { enable = true },
  },
}
