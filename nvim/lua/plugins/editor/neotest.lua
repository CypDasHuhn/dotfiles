return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
  },
  keys = {
    {
      '<leader>tr',
      function()
        require('neotest').run.run()
      end,
      desc = '[T]est [R]un nearest',
    },
    {
      '<leader>tR',
      function()
        require('neotest').run.run(vim.fn.expand '%')
      end,
      desc = '[T]est [R]un file',
    },
    {
      '<leader>tS',
      function()
        require('neotest').run.stop()
      end,
      desc = '[T]est [S]top',
    },
    {
      '<leader>ts',
      function()
        require('neotest').summary.toggle()
      end,
      desc = '[T]est [S]ummary',
    },
    {
      '<leader>to',
      function()
        require('neotest').output.open()
      end,
      desc = '[T]est [O]utput',
    },
    {
      ']t',
      function()
        require('neotest').jump.next { status = 'failed' }
      end,
      desc = 'Next failed test',
    },
    {
      '[t',
      function()
        require('neotest').jump.prev { status = 'failed' }
      end,
      desc = 'Previous failed test',
    },
  },
  opts = {
    status = { virtual_text = true },
    output = { open_on_run = true },
  },
}
