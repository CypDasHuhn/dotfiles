return {
  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  build = ':TSUpdate',
  config = function()
    local langs = require '.config.lang-packs.init'
    local own_parsers = { tl = true, gct = true }

    local parsers = vim.list_extend(
      { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' },
      langs.treesitter
    )
    parsers = vim.tbl_filter(function(p) return p ~= 'latex' end, parsers)

    local function enable_indent(bufnr)
      vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end

    local function enable_treesitter(bufnr)
      if pcall(vim.treesitter.start, bufnr) then
        enable_indent(bufnr)
      end
    end

    local ok, treesitter = pcall(require, 'nvim-treesitter')
    if ok and type(treesitter.setup) == 'function' then
      treesitter.setup()
      if #parsers > 0 and type(treesitter.install) == 'function' then
        pcall(function()
          treesitter.install(parsers)
        end)
      end

      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('nvim-treesitter-start', { clear = true }),
        callback = function(ev)
          enable_treesitter(ev.buf)
        end,
      })
    else
      require('nvim-treesitter.configs').setup {
        ensure_installed = parsers,
        highlight = {
          enable = true,
          disable = function(lang)
            if own_parsers[lang] then return true end
            return not pcall(vim.treesitter.language.inspect, lang)
          end,
        },
      }
    end
  end,
}
