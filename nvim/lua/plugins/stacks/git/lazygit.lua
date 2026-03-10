return {
  'kdheepak/lazygit.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  keys = {
    { '<leader>gg', '<cmd>LazyGit<cr>', desc = 'LazyGit' },
  },
  config = function()
    vim.g.lazygit_floating_window_use_plenary = 0
    -- pressing 'e' on a file in lazygit opens it in current nvim instance
    vim.g.lazygit_use_neovim_remote = 1
  end,
}
