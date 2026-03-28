return {
  'nvim-treesitter/nvim-treesitter',
  event = { 'BufReadPost', 'BufNewFile' },
  build = ':TSUpdate',
  config = function()
    local langs = require '.config.lang-packs.init'

    -- nvim-treesitter v1+ is a parser manager only; highlight/indent are Neovim built-ins
    require('nvim-treesitter.config').setup {}

    local parsers = vim.list_extend(
      { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' },
      langs.treesitter
    )
    parsers = vim.tbl_filter(function(p) return p ~= 'latex' end, parsers)
    require('nvim-treesitter.install').install(parsers)

    local hl_disabled = { latex = true }

    vim.api.nvim_create_autocmd('FileType', {
      callback = function(ev)
        if not hl_disabled[vim.bo[ev.buf].filetype] then
          pcall(vim.treesitter.start, ev.buf)
        end
      end,
    })
  end,
}
