-- TODO: Split up like in lsp-config for OSP

return {
  'saghen/blink.cmp',
  event = { 'BufReadPost', 'InsertEnter', 'CmdlineEnter' },
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
      ['<Tab>'] = false,
      ['<S-Tab>'] = false,
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
        -- mssql.nvim provides SQL Server completion; Dadbod remains available too.
        sql = { 'lsp', 'dadbod', 'buffer', 'path', 'snippets' },
        mysql = { 'dadbod', 'buffer', 'path', 'snippets' },
        plsql = { 'dadbod', 'buffer', 'path', 'snippets' },
      },
      providers = {
        lsp = {
          transform_items = function(_, items)
            for index = #items, 1, -1 do
              local item = items[index]
              if item.client_name == 'mssql_ls' then
                local text_edit = type(item.textEdit) == 'table' and item.textEdit or nil
                if type(item.label) ~= 'string' then
                  local fallback
                  local candidates = { item.filterText, item.insertText, text_edit and text_edit.newText }
                  for candidate_index = 1, 3 do
                    local value = candidates[candidate_index]
                    if type(value) == 'string' then
                      fallback = value
                      break
                    end
                  end
                  if type(fallback) == 'string' then
                    item.label = fallback
                  else
                    table.remove(items, index)
                    goto continue
                  end
                end

                for _, field in ipairs { 'filterText', 'insertText', 'sortText' } do
                  if type(item[field]) ~= 'string' then item[field] = nil end
                end
              end
              ::continue::
            end
            return items
          end,
        },
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
      paths = { '~/.config/snippets' },
    }
    vim.lsp.config('*', { capabilities = require('blink.cmp').get_lsp_capabilities() })
  end,
}
