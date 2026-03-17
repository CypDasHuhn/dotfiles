local function find_visible_sibling_line(state, node, from_start)
  local parent_id = node:get_parent_id()
  local line_count = vim.api.nvim_buf_line_count(state.bufnr)
  local start_line = from_start and 1 or line_count
  local end_line = from_start and line_count or 1
  local step = from_start and 1 or -1

  for line = start_line, end_line, step do
    local sibling = state.tree:get_node(line)
    if sibling and sibling.type ~= 'message' and sibling:get_parent_id() == parent_id then
      return line
    end
  end

  return nil
end

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
    'MunifTanjim/nui.nvim',
  },
  event = 'VeryLazy',
  keys = {
    { '<leader>e', ':Neotree toggle<CR>', desc = 'NeoTree reveal', silent = true },
  },
  opts = {
    filesystem = {
      commands = {
        -- region Clipboard commands
        system_copy = function(state)
          local fs = require 'lib.neo-tree-fs'
          local node = state.tree:get_node()
          if not node or node.type == 'message' then
            return
          end
          fs.write_clipboard('copy', { node:get_id() })
          require('neo-tree.sources.filesystem.commands').copy_to_clipboard(state)
        end,

        system_copy_visual = function(state, selected_nodes)
          local fs = require 'lib.neo-tree-fs'
          local paths = fs.collect_paths(selected_nodes)
          if #paths == 0 then
            return
          end
          fs.write_clipboard('copy', paths)
          require('neo-tree.sources.filesystem.commands').copy_to_clipboard_visual(state, selected_nodes)
        end,

        system_cut = function(state)
          local fs = require 'lib.neo-tree-fs'
          local node = state.tree:get_node()
          if not node or node.type == 'message' then
            return
          end
          fs.write_clipboard('cut', { node:get_id() })
          require('neo-tree.sources.filesystem.commands').cut_to_clipboard(state)
        end,

        system_cut_visual = function(state, selected_nodes)
          local fs = require 'lib.neo-tree-fs'
          local paths = fs.collect_paths(selected_nodes)
          if #paths == 0 then
            return
          end
          fs.write_clipboard('cut', paths)
          require('neo-tree.sources.filesystem.commands').cut_to_clipboard_visual(state, selected_nodes)
        end,

        copy_system_path = function(state)
          local node = state.tree:get_node()
          if not node or node.type == 'message' then
            return
          end

          local path = node:get_id()
          vim.fn.setreg('+', path)
          vim.notify('Copied path: ' .. path, vim.log.levels.INFO)
        end,

        move_to_parent = function(state)
          local renderer = require 'neo-tree.ui.renderer'
          local node = state.tree:get_node()
          if not node or node.type == 'message' then
            return
          end

          local parent_id = node:get_parent_id()
          if not parent_id then
            return
          end

          renderer.focus_node(state, parent_id)
        end,

        move_to_first_sibling = function(state)
          local node = state.tree:get_node()
          if not node or node.type == 'message' then
            return
          end

          local line = find_visible_sibling_line(state, node, true)
          if not line then
            return
          end

          vim.api.nvim_win_set_cursor(state.winid, { line, 0 })
        end,

        move_to_last_sibling = function(state)
          local node = state.tree:get_node()
          if not node or node.type == 'message' then
            return
          end

          local line = find_visible_sibling_line(state, node, false)
          if not line then
            return
          end

          vim.api.nvim_win_set_cursor(state.winid, { line, 0 })
        end,

        system_paste = function(state)
          local fs = require 'lib.neo-tree-fs'
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
          local fs = require 'lib.neo-tree-fs'
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
          local fs = require 'lib.neo-tree-fs'
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
          require('lib.neo-tree-fs').undo()
        end,

        redo = function(_)
          require('lib.neo-tree-fs').redo()
        end,
        -- endregion
      },

      window = {
        mappings = {
          ['<leader>E'] = 'close_window',
          ['Z'] = 'expand_all_nodes',
          ['<C-H>'] = 'toggle_hidden',
          h = 'move_to_parent',
          H = 'move_to_first_sibling',
          L = 'move_to_last_sibling',
          y = 'system_copy',
          Y = 'copy_system_path',
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
          require('lib.neo-tree-fs').track_add(path)
        end,
      },
      {
        event = 'file_renamed',
        handler = function(args)
          require('lib.neo-tree-fs').track_rename(args.source, args.destination)
        end,
      },
      -- endregion
    },
  },
}
