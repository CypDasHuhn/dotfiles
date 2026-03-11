local langs = require '.config.lang-packs.init'

return {
  'neovim/nvim-lspconfig',
  lazy = false,
  dependencies = {
    'mason-org/mason.nvim',
    'mason-org/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    { 'j-hui/fidget.nvim', opts = {} },
    'saghen/blink.cmp',
    'folke/lazydev.nvim',
  },
  config = function()
    local server_aliases = {
      volar = 'vue_ls',
    }
    local kotlin_root_files = {
      'settings.gradle',
      'settings.gradle.kts',
      'build.xml',
      'pom.xml',
      'build.gradle',
      'build.gradle.kts',
    }

    local function register_custom_servers()
      vim.lsp.config('kotlin_lsp', {
        cmd = { 'kotlin-lsp' },
        filetypes = { 'kotlin' },
        root_markers = { kotlin_root_files },
        init_options = {
          storagePath = vim.fn.stdpath 'data' .. '/kotlin-lsp',
        },
      })

      vim.lsp.config('plantuml_lsp', {
        cmd = { 'plantuml-lsp' },
        filetypes = { 'plantuml' },
        root_markers = { '.git' },
        single_file_support = true,
      })
    end

    local function normalize_servers(server_map)
      local normalized = {}

      for name, config in pairs(server_map) do
        normalized[server_aliases[name] or name] = config
      end

      return normalized
    end

    local function split_servers(server_map)
      local mason_servers = {}
      local manual_servers = {}

      for name, config in pairs(server_map) do
        if config.mason == false then
          manual_servers[name] = config
        else
          mason_servers[name] = config
        end
      end

      return mason_servers, manual_servers
    end

    local function setup_server(server_name, server)
      server = vim.deepcopy(server or {})
      server.mason = nil
      vim.lsp.config(server_name, server)
      vim.lsp.enable(server_name)
    end

    require('mason').setup {
      registries = {
        'github:mason-org/mason-registry',
        'github:Crashdummyy/mason-registry',
      },
    }

    vim.lsp.config('*', {
      capabilities = require('blink.cmp').get_lsp_capabilities(),
    })

    local servers = vim.tbl_deep_extend('force', {
      lua_ls = {
        settings = {
          Lua = {
            completion = { callSnippet = 'Replace' },
          },
        },
      },
    }, normalize_servers(langs.servers))

    register_custom_servers()

    local mason_servers, manual_servers = split_servers(servers)

    require('mason-lspconfig').setup {
      ensure_installed = vim.tbl_keys(mason_servers),
      automatic_enable = false,
    }

    for server_name, server in pairs(mason_servers) do
      setup_server(server_name, server)
    end

    for server_name, server in pairs(manual_servers) do
      setup_server(server_name, server)
    end

    local tools = { 'stylua' }
    vim.list_extend(tools, langs.tools)
    require('mason-tool-installer').setup { ensure_installed = tools }

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

    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc, mode)
          mode = mode or 'n'
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        local function client_supports(method)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          return client and client:supports_method(method, event.buf)
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

        if client_supports(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
          local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
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

        if client_supports(vim.lsp.protocol.Methods.textDocument_inlayHint) then
          map('<leader>th', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
          end, '[T]oggle Inlay [H]ints')
        end
      end,
    })
  end,
}
