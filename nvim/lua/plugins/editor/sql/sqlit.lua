return {
  'Maxteabag/sqlit.nvim',
  opts = {},
  cmd = 'Sqlit',
  keys = {
    {
      '<leader>D',
      function()
        require('sqlit').open()
      end,
      desc = 'Database (sqlit)',
    },
  },
}
