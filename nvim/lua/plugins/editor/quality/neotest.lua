return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
  },
  keys = {
    {
      '<leader>or',
      function()
        require('neotest').run.run()
      end,
      desc = 'Test [R]un nearest',
    },
    {
      '<leader>oR',
      function()
        require('neotest').run.run(vim.fn.expand '%')
      end,
      desc = 'Test [R]un file',
    },
    {
      '<leader>oS',
      function()
        require('neotest').run.stop()
      end,
      desc = 'Test [S]top',
    },
    {
      '<leader>os',
      function()
        require('neotest').summary.toggle()
      end,
      desc = 'Test [S]ummary',
    },
    {
      '<leader>oo',
      function()
        require('neotest').output.open()
      end,
      desc = 'Test [O]utput',
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
