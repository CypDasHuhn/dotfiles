return {
  'akinsho/bufferline.nvim',
  version = '*',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
    'moll/vim-bbye', -- better buffer deletion
  },
  config = function()
    require('bufferline').setup {
      options = {
        mode = 'buffers',
        numbers = 'ordinal',
        close_command = 'Bdelete! %d',
        right_mouse_command = 'Bdelete! %d',
        left_mouse_command = 'buffer %d',
        always_show_bufferline = true,
        middle_mouse_command = nil,
        indicator = {
          style = 'underline',
        },
        buffer_close_icon = '󰅖',
        modified_icon = '●',
        close_icon = '',
        left_trunc_marker = '',
        right_trunc_marker = '',
        separator_style = 'thin',
        offsets = {
          {
            filetype = 'NvimTree',
            text = 'File Explorer',
            highlight = 'Directory',
            separator = true,
          },
        },
        show_buffer_close_icons = true,
        show_close_icon = true,
        persist_buffer_sort = true,
      },
    }
  end,
  keys = {
    -- Navigate buffers
    { 'H', '<cmd>BufferLineCyclePrev<cr>', desc = 'Previous buffer' },
    { 'L', '<cmd>BufferLineCycleNext<cr>', desc = 'Next buffer' },

    -- Move buffers
    { '<A-H>', '<cmd>BufferLineMovePrev<cr>', desc = 'Move buffer left' },
    { '<A-L>', '<cmd>BufferLineMoveNext<cr>', desc = 'Move buffer right' },

    -- Pick buffers
    { '<leader>bp', '<cmd>BufferLinePick<cr>', desc = 'Pick buffer' },
    { '<leader>bc', '<cmd>BufferLinePickClose<cr>', desc = 'Pick close' },

    -- Pin buffer
    { '<leader>bP', '<cmd>BufferLineTogglePin<cr>', desc = 'Toggle pin' },

    -- Close buffers
    { '<leader>bd', '<cmd>Bdelete<cr>', desc = 'Delete buffer' },
    { '<leader>bD', '<cmd>Bdelete!<cr>', desc = 'Delete buffer (force)' },
    { '<leader>bo', '<cmd>BufferLineCloseOthers<cr>', desc = 'Close others' },
    { '<leader>br', '<cmd>BufferLineCloseRight<cr>', desc = 'Close right' },
    { '<leader>bl', '<cmd>BufferLineCloseLeft<cr>', desc = 'Close left' },

    -- Go to buffer by number
    { '<leader>b1', '<cmd>BufferLineGoToBuffer 1<cr>', desc = 'Go to buffer 1' },
    { '<leader>b2', '<cmd>BufferLineGoToBuffer 2<cr>', desc = 'Go to buffer 2' },
    { '<leader>b3', '<cmd>BufferLineGoToBuffer 3<cr>', desc = 'Go to buffer 3' },
    { '<leader>b4', '<cmd>BufferLineGoToBuffer 4<cr>', desc = 'Go to buffer 4' },
    { '<leader>b5', '<cmd>BufferLineGoToBuffer 5<cr>', desc = 'Go to buffer 5' },
    { '<leader>b6', '<cmd>BufferLineGoToBuffer 6<cr>', desc = 'Go to buffer 6' },
    { '<leader>b7', '<cmd>BufferLineGoToBuffer 7<cr>', desc = 'Go to buffer 7' },
    { '<leader>b8', '<cmd>BufferLineGoToBuffer 8<cr>', desc = 'Go to buffer 8' },
    { '<leader>b9', '<cmd>BufferLineGoToBuffer 9<cr>', desc = 'Go to buffer 9' },
  },
}
