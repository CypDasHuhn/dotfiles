return {
  'Exafunction/windsurf.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  config = function()
    vim.keymap.set('n', '<leader>tc', '<cmd>Codeium Toggle', { buffer = true })

    require('codeium').setup {
      -- Using blink.cmp integration, not nvim-cmp.
      enable_cmp_source = false,
      virtual_text = {
        enabled = true,
        manual = false,
        map_keys = true,
        accept_fallback = false,
        key_bindings = {
          accept = '<C-i>',
          next = '<C-,>',
          prev = '<C-.>',
          clear = '<C-x>',
          accept_word = false,
          accept_line = false,
        },
      },
    }
  end,
}
