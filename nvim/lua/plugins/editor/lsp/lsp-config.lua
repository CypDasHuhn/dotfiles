-- Mason 2.0 / mason-lspconfig 2.0 compatible setup
return {
  {
    'mason-org/mason.nvim',
    lazy = false,
    opts = {
      registries = {
        'github:mason-org/mason-registry',
        'github:Crashdummyy/mason-registry',
      },
    },
  },
  {
    'mason-org/mason-lspconfig.nvim',
    lazy = false,
    dependencies = {
      'mason-org/mason.nvim',
      'neovim/nvim-lspconfig',
      'folke/lazydev.nvim', -- must load before lua_ls starts
    },
    config = function()
      local langs = require '.config.lang-packs.init'

      -- Collect all servers: base + language packs
      local servers = vim.tbl_deep_extend('force', {
        lua_ls = {
          settings = {
            Lua = {
              completion = { callSnippet = 'Replace' },
            },
          },
        },
      }, langs.servers)

      -- Configure each server and track which need Mason
      local mason_servers = {}
      for server_name, server_opts in pairs(servers) do
        local opts = vim.tbl_deep_extend('force', {}, server_opts)
        local is_external = opts.mason == false
        opts.mason = nil

        -- Configure the server
        vim.lsp.config(server_name, opts)

        if is_external then
          -- External servers: enable directly
          vim.lsp.enable(server_name)
        else
          -- Mason servers: let mason-lspconfig handle enabling
          table.insert(mason_servers, server_name)
        end
      end

      -- mason-lspconfig auto-enables installed servers (automatic_enable = true is default)
      require('mason-lspconfig').setup {
        ensure_installed = mason_servers,
      }
    end,
  },
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    lazy = false,
    dependencies = { 'mason-org/mason.nvim' },
    config = function()
      local langs = require '.config.lang-packs.init'
      local tools = { 'stylua' }
      vim.list_extend(tools, langs.tools)
      require('mason-tool-installer').setup { ensure_installed = tools }
    end,
  },
  {
    'neovim/nvim-lspconfig',
    lazy = false,
    dependencies = {
      { 'j-hui/fidget.nvim', opts = {} },
      'saghen/blink.cmp',
    },
    config = function()
      -- Broadcast blink.cmp capabilities to all LSP servers
      vim.lsp.config('*', {
        capabilities = require('blink.cmp').get_lsp_capabilities(),
      })

      -- Diagnostic Config
      vim.diagnostic.config {
        severity_sort = true,
        float = { border = 'rounded', source = 'if_many' },
        underline = true,
        signs = vim.g.have_nerd_font and {
          text = {
            [vim.diagnostic.severity.ERROR] = '󰅚 ',
            [vim.diagnostic.severity.WARN] = '󰀪 ',
            [vim.diagnostic.severity.INFO] = '󰋽 ',
            [vim.diagnostic.severity.HINT] = '󰌶 ',
          },
        } or {},
        virtual_text = false,
        virtual_lines = true,
      }

      -- LspAttach keymaps
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
          map('grr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
          map('gri', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
          map('grd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
          map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
          map('gO', require('telescope.builtin').lsp_document_symbols, 'Open Document Symbols')
          map('gW', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Open Workspace Symbols')
          map('grt', require('telescope.builtin').lsp_type_definitions, '[G]oto [T]ype Definition')

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
            local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = function()
                local c = vim.lsp.get_client_by_id(event.data.client_id)
                if c and c:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
                  vim.lsp.buf.document_highlight()
                end
              end,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end
        end,
      })
    end,
  },
}
