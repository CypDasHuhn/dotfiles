return {
  'saghen/blink.cmp',
  event = 'VeryLazy',
  version = '1.*',
  dependencies = {
    'Exafunction/codeium.nvim',
    {
      'L3MON4D3/LuaSnip',
      version = '2.*',
      build = (function()
        if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
          return
        end
        return 'make install_jsregexp'
      end)(),
    },
    'folke/lazydev.nvim',
  },
  --- @module 'blink.cmp'
  --- @type blink.cmp.Config
  opts = {
    keymap = {
      preset = 'default',
    },

    appearance = {
      nerd_font_variant = 'mono',
    },

    completion = {
      documentation = { auto_show = false, auto_show_delay_ms = 500 },
    },

    sources = {
      default = { 'lsp', 'path', 'snippets', 'lazydev', 'codeium' },
      per_filetype = {
        -- SQL files use dadbod completion instead of LSP
        sql = { 'dadbod', 'buffer', 'path', 'snippets' },
        mysql = { 'dadbod', 'buffer', 'path', 'snippets' },
        plsql = { 'dadbod', 'buffer', 'path', 'snippets' },
      },
      providers = {
        lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
        codeium = { name = 'Codeium', module = 'codeium.blink', async = true },
        dadbod = {
          name = 'Dadbod',
          module = 'blink.cmp.sources.complete_func',
          score_offset = 85,
          opts = {
            complete_func = function()
              return vim.bo.omnifunc
            end,
          },
        },
      },
    },

    snippets = { preset = 'luasnip' },

    fuzzy = { implementation = 'lua' },

    signature = { enabled = true },

    cmdline = {
      enabled = true,
      keymap = { preset = 'cmdline' },
      completion = {
        menu = { auto_show = true },
        ghost_text = { enabled = true },
      },
    },
  },
  config = function(_, opts)
    require('blink.cmp').setup(opts)
    require('luasnip.loaders.from_vscode').lazy_load {
      paths = { vim.fn.stdpath 'config' .. '/snippets' },
    }
  end,
}
