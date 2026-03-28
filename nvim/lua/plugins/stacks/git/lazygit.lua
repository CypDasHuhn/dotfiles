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

    _G.lg_open = function(filename, line)
      local lg_win = vim.api.nvim_get_current_win()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_config(win).relative == '' then
          vim.api.nvim_set_current_win(win)
          break
        end
      end
      pcall(vim.api.nvim_win_close, lg_win, true)
      vim.cmd('edit ' .. (line and ('+' .. line .. ' ') or '') .. vim.fn.fnameescape(filename))
      return ''
    end
  end,
}
