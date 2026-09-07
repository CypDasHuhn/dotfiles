return {
  'stevearc/aerial.nvim',
  event = 'VeryLazy',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  keys = {
    { '<leader>no', '<cmd>AerialToggle!<CR>', desc = 'Toggle outline (keep focus)' },
    { '<leader>nN', '<cmd>AerialNext<CR>', desc = 'Jump to next symbol (Aerial)' },
    { '<leader>nP', '<cmd>AerialPrev<CR>', desc = 'Jump to previous symbol (Aerial)' },
  },
  opts = {
    backends = {
      ['_'] = { 'lsp', 'treesitter', 'markdown', 'asciidoc', 'man' },
    },
    lsp = {
      priority = {
        vue_ls = 20,
        ts_ls = 10,
      },
    },
    keymaps = {
      -- `H`/`L` default to recursive tree close/open; free them so the global
      -- <S-h>/<S-l> window-navigation binds (config/binds/windows.lua) work here.
      -- Recursive open/close stays available on `zO`/`zA`.
      H = false,
      L = false,
    },
  },
}
