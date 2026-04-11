return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'master',
  event = { 'BufReadPost', 'BufNewFile' },
  build = ':TSUpdate',
  config = function()
    local langs = require '.config.lang-packs.init'

    local parsers = vim.list_extend(
      { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' },
      langs.treesitter
    )
    parsers = vim.tbl_filter(function(p) return p ~= 'latex' end, parsers)

    require('nvim-treesitter.configs').setup {
      ensure_installed = parsers,
      highlight = {
        enable = true,
        disable = function(lang)
          local own_parsers = { tl = true, gct = true }
          if own_parsers[lang] then return true end
          return not pcall(vim.treesitter.language.inspect, lang)
        end,
      },
    }
  end,
}
