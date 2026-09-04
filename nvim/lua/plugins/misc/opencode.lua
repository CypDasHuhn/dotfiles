return {
  'nickjvandyke/opencode.nvim',
  event = 'VeryLazy',
  init = function()
    vim.g.opencode_opts = {
      server = {
        start = false,
      },
    }
  end,
  config = function()
    vim.keymap.set({ 'n', 'x' }, '<leader>aa', function()
      require('opencode').ask('@this: ')
    end, { desc = 'Ask OpenCode' })

    vim.keymap.set({ 'n', 'x' }, '<leader>as', function()
      require('opencode').select()
    end, { desc = 'OpenCode: Select' })
  end,
}
