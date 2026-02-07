vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.api.nvim_set_hl(0, 'DiagnosticUnnecessary', { undercurl = true })
vim.diagnostic.config {
  underline = true, -- this is already set by default
  virtual_lines = true,
}
vim.keymap.set('n', '<leader>d', function()
  local new_config = not vim.diagnostic.config().virtual_lines
  vim.diagnostic.config { virtual_lines = new_config }
end, { desc = 'Toggle diagnostic virtual_lines' })

-- ctrl W + d: open diagnostic popup

vim.keymap.set('n', '<leader>bp', '<cmd>bprev<CR>', { desc = 'previous buffer' })
vim.keymap.set('n', '<leader>bn', '<cmd>bnext<CR>', { desc = 'next buffer' })
vim.keymap.set('n', '<leader>bd', '<cmd>bdelete<CR>', { desc = 'delete buffer' })

vim.keymap.set('n', '<c-j>', '<cmd>wincmd j<CR>')
vim.keymap.set('n', '<c-k>', '<cmd>wincmd k<CR>')
vim.keymap.set('n', '<c-l>', '<cmd>wincmd l<CR>')
vim.keymap.set('n', '<c-h>', '<cmd>wincmd h<CR>')

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.modeline = true

-- Enable spell check
vim.opt.spell = true
vim.opt.spelllang = { 'en', 'de' }

vim.g.have_nerd_font = 'true'
vim.opt.cursorline = true
vim.o.scrolloff = 8
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

vim.opt.winborder = 'double'

-- TODO: Learn vim diagraphs for öü
-- learn jumplist?

vim.opt.clipboard = 'unnamedplus'

vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 0

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
      { out, 'WarningMsg' },
      { '\nPress any key to exit...' },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup {
  'marko-cerovac/material.nvim',
  'AlexvZyl/nordic.nvim', --alternative color scheme
  'mason-org/mason.nvim',
  'hrsh7th/nvim-cmp',
  'hrsh7th/cmp-buffer',
  'hrsh7th/cmp-path',
  'hrsh7th/cmp-cmdline',
  'saadparwaiz1/cmp_luasnip',
  'hrsh7th/cmp-nvim-lsp',
  'L3MON4D3/LuaSnip',
  'nvim-telescope/telescope.nvim',
  'nvim-lua/plenary.nvim',
  'nvim-neo-tree/neo-tree.nvim',
  'nvim-tree/nvim-web-devicons',
  'MunifTanjim/nui.nvim',
  'nvim-treesitter/nvim-treesitter',
  'neovim/nvim-lspconfig',
  'brenoprata10/nvim-highlight-colors',
  'lewis6991/gitsigns.nvim',
  'nvim-lualine/lualine.nvim',
}

require('nordic').setup { reduced_blue = false }
vim.cmd 'colorscheme nordic'

require('nvim-highlight-colors').setup {
  render = 'background',
}

local cmp = require 'cmp'
local luasnip = require 'luasnip'

cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert {
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm { select = true },
    ['<C-k>'] = cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Insert },
    ['<C-j>'] = cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Insert },
  },
  sources = cmp.config.sources {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'buffer' },
    { name = 'path' },
  },
}

cmp.setup.cmdline({ '/', '?' }, {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = 'buffer' },
  },
})

cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = 'path' },
  }, {
    { name = 'cmdline' },
  }),
})

local builtin = require 'telescope.builtin'

vim.keymap.set('n', '<leader><leader>', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>g', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>bb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>h', builtin.help_tags, { desc = 'Telescope help tags' })

vim.keymap.set('n', '<leader>e', function()
  require('neo-tree.command').execute {
    toggle = true,
    source = 'filesystem',
    position = 'current',
    reveal = true,
  }
end, { desc = 'Explore NeoTree' })

require('nvim-treesitter.configs').setup {
  ensure_installed = {
    'lua',
    'vim',
    'vimdoc',
    'markdown',
    'markdown_inline',
    'vue',
    'javascript',
    'typescript',
    'html',
    'css',
  },

  sync_install = false,
  auto_install = true,

  ignore_install = {},
  indent = { enable = true },
  folds = { enable = true },
  highlight = { enable = true },
}

require('mason').setup()
local mason_registry = require 'mason-registry'

local function install_missing_server(server_name)
  if mason_registry.is_installed(server_name) then
    return
  end

  local command = 'MasonInstall ' .. server_name
  vim.cmd(command)
end

local language_servers = { 'lua-language-server', 'vtsls', 'vue-language-server', 'marksman' }

for _index, server in ipairs(language_servers) do
  install_missing_server(server)
end

vim.lsp.config('luals', {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { { '.luarc.json', '.luarc.jsonc' }, '.git' },
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
      },
      workspace = {
        library = { vim.env.VIMRUNTIME },
      },
    },
  },
})

vim.lsp.enable 'luals'

local vue_language_server_path = vim.fn.expand '$MASON/packages' .. '/vue-language-server' .. '/node_modules/@vue/language-server'

local tsserver_filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' }
local vue_plugin = {
  name = '@vue/typescript-plugin',
  location = vue_language_server_path,
  languages = { 'vue' },
  configNamespace = 'typescript',
}

local vtsls_config = {
  settings = {
    vtsls = {
      tsserver = {
        globalPlugins = {
          vue_plugin,
        },
      },
    },
  },
  filetypes = tsserver_filetypes,
}

local vue_ls_config = {}

vim.lsp.config('vtsls', vtsls_config)
vim.lsp.config('vue_ls', vue_ls_config)

vim.lsp.enable 'vtsls'
vim.lsp.enable 'vue_ls'

vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = { '*.lua', '*.vue', '*.ts', '*.js' },
  callback = function()
    vim.lsp.buf.format { async = false }
  end,
})

vim.keymap.set('n', '<leader>ca', function()
  vim.lsp.buf.code_action()
end, { desc = 'code action' })

require('gitsigns').setup {
  signs = {
    add = { text = '┃' },
    change = { text = '┃' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
    untracked = { text = '┆' },
  },
  signs_staged = {
    add = { text = '┃' },
    change = { text = '┃' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
    untracked = { text = '┆' },
  },
  signs_staged_enable = true,
  signcolumn = true,
  numhl = false,
  linehl = false,
  word_diff = false,
  watch_gitdir = {
    follow_files = true,
  },
  auto_attach = true,
  attach_to_untracked = false,
  current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
  current_line_blame_opts = {
    virt_text = true,
    virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
    delay = 1000,
    ignore_whitespace = false,
    virt_text_priority = 100,
    use_focus = true,
  },
  current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
  sign_priority = 6,
  update_debounce = 100,
  status_formatter = nil, -- Use default
  max_file_length = 40000, -- Disable if file is longer than this (in lines)
  preview_config = {
    style = 'minimal',
    relative = 'cursor',
    row = 0,
    col = 1,
  },
}
require('lualine').setup {}
vim.opt.showmode = false
vim.o.cmdheight = 0
