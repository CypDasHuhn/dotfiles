-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  lazy = false,
  keys = {
    { '<leader>e', ':Neotree toggle<CR>', desc = 'NeoTree reveal', silent = true },
  },
  opts = {
    filesystem = {
      window = {
        mappings = {
          ['<leader>E'] = 'close_window',
          ['Z'] = 'expand_all_nodes',
          y = function(state)
            local node = state.tree:get_node()
            local path = node:get_id()
            local clipboard_file = vim.fn.stdpath 'data' .. '/neo-tree-clipboard.json'
            local data = vim.json.encode { action = 'copy', paths = { path } }
            vim.fn.writefile({ data }, clipboard_file)
            -- Also trigger neo-tree's internal copy
            require('neo-tree.sources.filesystem.commands').copy_to_clipboard(state)
          end,
          x = function(state)
            local node = state.tree:get_node()
            local path = node:get_id()
            local clipboard_file = vim.fn.stdpath 'data' .. '/neo-tree-clipboard.json'
            local data = vim.json.encode { action = 'cut', paths = { path } }
            vim.fn.writefile({ data }, clipboard_file)
            require('neo-tree.sources.filesystem.commands').cut_to_clipboard(state)
          end,
          p = function(state)
            local clipboard_file = vim.fn.stdpath 'data' .. '/neo-tree-clipboard.json'
            if vim.fn.filereadable(clipboard_file) == 0 then
              require('neo-tree.sources.filesystem.commands').paste_from_clipboard(state)
              return
            end
            local content = vim.fn.readfile(clipboard_file)
            if #content == 0 then
              require('neo-tree.sources.filesystem.commands').paste_from_clipboard(state)
              return
            end
            local ok, clip = pcall(vim.json.decode, content[1])
            if not ok or not clip or not clip.paths then
              require('neo-tree.sources.filesystem.commands').paste_from_clipboard(state)
              return
            end
            local node = state.tree:get_node()
            local dest = node:get_id()
            if vim.fn.isdirectory(dest) == 0 then
              dest = vim.fn.fnamemodify(dest, ':h')
            end
            for _, src in ipairs(clip.paths) do
              local name = vim.fn.fnamemodify(src, ':t')
              local target = dest .. '/' .. name
              if clip.action == 'cut' then
                vim.fn.rename(src, target)
              else
                if vim.fn.isdirectory(src) == 1 then
                  if vim.fn.has 'win32' == 1 then
                    vim.fn.system { 'xcopy', src, target .. '\\', '/E', '/I', '/Q' }
                  else
                    vim.fn.system { 'cp', '-r', src, target }
                  end
                else
                  vim.uv.fs_copyfile(src, target)
                end
              end
            end
            if clip.action == 'cut' then
              vim.fn.delete(clipboard_file)
            end
            require('neo-tree.sources.manager').refresh 'filesystem'
          end,
        },
      },
      follow_current_file = {
        enabled = true,
        leave_dirs_open = false,
      },
    },
    event_handlers = {
      {
        event = 'file_open_requested',
        handler = function()
          require('neo-tree.command').execute { action = 'close' }
        end,
      },
      {
        event = 'neo_tree_buffer_enter',
        handler = function()
          vim.opt_local.number = true
          vim.opt_local.relativenumber = true
        end,
      },
    },
  },
}
