return {
  'akinsho/bufferline.nvim',
  version = '*',
  lazy = false,
  priority = 1000,
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
        buffer_close_icon = '',
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
        show_buffer_close_icons = false,
        show_close_icon = false,
        persist_buffer_sort = true,
      },
    }

    -- region Custom command to close unpinned buffers
    vim.api.nvim_create_user_command('BufferLineCloseUnpinned', function()
      local current_buf = vim.api.nvim_get_current_buf()

      -- Bufferline stores pins in a separate location
      local bufferline_config = require 'bufferline.config'
      local pinned = {}

      -- Try to get pinned buffers from bufferline's groups
      local ok, groups = pcall(require, 'bufferline.groups')
      if ok then
        local pinned_group = groups.get_all()
        for _, group in pairs(pinned_group) do
          if group.name == 'pinned' then
            for _, buf in ipairs(group.items or {}) do
              pinned[buf] = true
            end
          end
        end
      end

      -- Also check state components
      local state = require 'bufferline.state'
      for _, component in ipairs(state.components or {}) do
        if component.pinned or component.group == 'pinned' then
          pinned[component.id] = true
        end
      end

      -- Close all non-pinned, non-current buffers
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted and buf ~= current_buf and not pinned[buf] then
          vim.cmd('Bdelete! ' .. buf)
        end
      end
    end, {})
    -- endregion

    -- region Keymaps
    local map = vim.keymap.set
    -- Navigate buffers
    for _, mode in ipairs { 'n', 'i', 'v', 't' } do
      map(mode, '<A-h>', '<cmd>BufferLineCyclePrev<cr>', { desc = 'Previous buffer' })
      map(mode, '<A-l>', '<cmd>BufferLineCycleNext<cr>', { desc = 'Next buffer' })
    end
    -- Move buffers
    map('n', '<A-y>', '<cmd>BufferLineMovePrev<cr>', { desc = 'Move buffer left' })
    map('n', '<A-o>', '<cmd>BufferLineMoveNext<cr>', { desc = 'Move buffer right' })
    -- Pin buffer
    map('n', '<leader>bp', '<cmd>BufferLineTogglePin<cr>', { desc = 'Toggle pin' })
    -- Close buffers
    map('n', '<leader>bd', '<cmd>Bdelete<cr>', { desc = 'Delete buffer' })
    map('n', '<leader>bD', '<cmd>Bdelete!<cr>', { desc = 'Delete buffer (force)' })
    map('n', '<leader>bo', '<cmd>BufferLineCloseUnpinned<cr>', { desc = 'Close unpinned' })
    map('n', '<leader>bO', function()
      local buf = vim.api.nvim_get_current_buf()
      local state = require 'bufferline.state'
      local pinned = false
      for _, component in ipairs(state.components or {}) do
        if component.id == buf and (component.pinned or component.group == 'pinned') then
          pinned = true
          break
        end
      end
      vim.cmd 'BufferLineCloseUnpinned'
      if not pinned then
        vim.cmd 'Bdelete'
      end
    end, { desc = 'Close unpinned + current if unpinned' })
    map('n', '<leader>br', '<cmd>BufferLineCloseRight<cr>', { desc = 'Close right' })
    map('n', '<leader>bl', '<cmd>BufferLineCloseLeft<cr>', { desc = 'Close left' })
    -- Go to buffer by number
    for i = 1, 9 do
      map('n', '<leader>b' .. i, '<cmd>BufferLineGoToBuffer ' .. i .. '<cr>', { desc = 'Go to buffer ' .. i })
    end
    -- endregion
  end,
}
