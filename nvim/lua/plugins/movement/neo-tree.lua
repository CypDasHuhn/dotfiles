local fs = require 'lib.neo-tree-fs'

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
    'MunifTanjim/nui.nvim',
  },
  lazy = false,
  keys = {
    { '<leader>e', ':Neotree toggle<CR>', desc = 'NeoTree reveal', silent = true },
  },
  opts = {
    filesystem = {
      commands = {
        -- region Clipboard commands
        system_copy = function(state)
          local node = state.tree:get_node()
          if not node or node.type == 'message' then
            return
          end
          fs.write_clipboard('copy', { node:get_id() })
          require('neo-tree.sources.filesystem.commands').copy_to_clipboard(state)
        end,

        system_copy_visual = function(state, selected_nodes)
          local paths = fs.collect_paths(selected_nodes)
          if #paths == 0 then
            return
          end
          fs.write_clipboard('copy', paths)
          require('neo-tree.sources.filesystem.commands').copy_to_clipboard_visual(state, selected_nodes)
        end,

        system_cut = function(state)
          local node = state.tree:get_node()
          if not node or node.type == 'message' then
            return
          end
          fs.write_clipboard('cut', { node:get_id() })
          require('neo-tree.sources.filesystem.commands').cut_to_clipboard(state)
        end,

        system_cut_visual = function(state, selected_nodes)
          local paths = fs.collect_paths(selected_nodes)
          if #paths == 0 then
            return
          end
          fs.write_clipboard('cut', paths)
          require('neo-tree.sources.filesystem.commands').cut_to_clipboard_visual(state, selected_nodes)
        end,

        system_paste = function(state)
          local node = state.tree:get_node()
          local dest = node and node:get_id() or nil
          if not dest or dest == '' then
            require('neo-tree.sources.filesystem.commands').paste_from_clipboard(state)
            return
          end
          if vim.fn.isdirectory(dest) == 0 then
            dest = vim.fn.fnamemodify(dest, ':h')
          end

          if fs.paste(dest) then
            require('neo-tree.sources.manager').refresh 'filesystem'
          else
            -- Fallback to built-in paste
            require('neo-tree.sources.filesystem.commands').paste_from_clipboard(state)
          end
        end,
        -- endregion

        -- region Trash command (safer delete)
        trash = function(state)
          local node = state.tree:get_node()
          if not node or node.type == 'message' then
            return
          end
          local path = node:get_id()
          local name = vim.fn.fnamemodify(path, ':t')

          vim.ui.select({ 'Yes', 'No' }, {
            prompt = 'Trash "' .. name .. '"?',
          }, function(choice)
            if choice == 'Yes' then
              if fs.trash(path) then
                require('neo-tree.sources.manager').refresh 'filesystem'
              end
            end
          end)
        end,

        trash_visual = function(state, selected_nodes)
          local paths = fs.collect_paths(selected_nodes)
          if #paths == 0 then
            return
          end

          vim.ui.select({ 'Yes', 'No' }, {
            prompt = 'Trash ' .. #paths .. ' item(s)?',
          }, function(choice)
            if choice == 'Yes' then
              if fs.trash(paths) then
                require('neo-tree.sources.manager').refresh 'filesystem'
              end
            end
          end)
        end,
        -- endregion

        -- region Undo/Redo commands
        undo = function(_)
          fs.undo()
        end,

        redo = function(_)
          fs.redo()
        end,
        -- endregion
      },

      window = {
        mappings = {
          ['<leader>E'] = 'close_window',
          ['Z'] = 'expand_all_nodes',
          y = 'system_copy',
          x = 'system_cut',
          p = 'system_paste',
          d = 'trash',
          u = 'undo',
          ['<C-r>'] = 'redo',
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
      -- region Track add/rename for undo
      {
        event = 'file_added',
        handler = function(path)
          fs.track_add(path)
        end,
      },
      {
        event = 'file_renamed',
        handler = function(args)
          fs.track_rename(args.source, args.destination)
        end,
      },
      -- endregion
    },
  },
}
