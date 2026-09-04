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

-- Session-local preference for merging single-child dirs into one line.
-- Kept in sync with the `group_empty_dirs` default in `opts`; resets on restart.
local merge_single_child_dirs = true

local MAX_DRILL_DEPTH = 100

local function visible_children(tree, id)
  local visible = {}
  for _, child in ipairs(tree:get_nodes(id)) do
    if child.type == 'file' or child.type == 'directory' then
      table.insert(visible, child)
    end
  end
  return visible
end

local function tree_node(tree, id)
  if not id then
    return nil
  end
  local ok, node = pcall(tree.get_node, tree, id)
  if ok and node then
    return node
  end
  return nil
end

local open_single_child_dir

local function continue_drill(state, path, parent_id, depth)
  if depth > MAX_DRILL_DEPTH then
    return
  end
  local tree = state.tree
  local renderer = require 'neo-tree.ui.renderer'

  local node = tree_node(tree, path)
  if node and node.type == 'directory' and node:is_expanded() then
    local children = visible_children(tree, path)
    if #children == 1 and children[1].type == 'directory' and not children[1]:is_expanded() then
      open_single_child_dir(state, children[1]:get_id(), path, depth + 1)
    else
      -- reached a directory with several entries (or none): stop drilling
      renderer.focus_node(state, path)
    end
  elseif not node and parent_id then
    -- the opened dir was merged into a single collapsed child at the parent level
    for _, child in ipairs(visible_children(tree, parent_id)) do
      if child.type == 'directory' and child:get_id() ~= path and vim.startswith(child:get_id(), path .. '/') then
        open_single_child_dir(state, child:get_id(), parent_id, depth + 1)
        return
      end
    end
  end
end

open_single_child_dir = function(state, path, parent_id, depth)
  if depth > MAX_DRILL_DEPTH then
    return
  end
  local tree = state.tree
  local node = tree_node(tree, path)
  if not node or node.type ~= 'directory' or node:is_expanded() then
    return
  end

  local fs = require 'neo-tree.sources.filesystem'
  local on_done = function()
    vim.schedule(function()
      continue_drill(state, path, parent_id, depth)
    end)
  end

  if node.loaded == false then
    -- children not scanned yet; fs.toggle_directory calls back once they are rendered
    fs.toggle_directory(state, node, nil, false, false, on_done)
  else
    fs.toggle_directory(state, node)
    on_done()
  end
end

local function open_recursively(state)
  local tree = state.tree
  local ok, node = pcall(tree.get_node, tree)
  if not (ok and node) or node.type ~= 'directory' or node:is_expanded() then
    return
  end
  open_single_child_dir(state, node:get_id(), node:get_parent_id(), 0)
end

local function toggle_merge_single_child_dirs()
  merge_single_child_dirs = not merge_single_child_dirs
  local manager = require 'neo-tree.sources.manager'
  manager._for_each_state('filesystem', function(state)
    state.group_empty_dirs = merge_single_child_dirs
  end)
  manager.refresh('filesystem')
  vim.notify('Merge single-child directories: ' .. (merge_single_child_dirs and 'on' or 'off'))
end

return {
  'nvim-neo-tree/neo-tree.nvim',
  essential = true,
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
    'MunifTanjim/nui.nvim',
  },
  cmd = 'Neotree',
  keys = {
    { '<leader>e', ':Neotree toggle<CR>', desc = 'NeoTree reveal', silent = true },
  },
  opts = {
    nesting_rules = require 'config.neo-tree-nesting',
    filesystem = {
      commands = {
        -- Open that recursively descends through directories whose only child is
        -- another directory, until a directory with several entries (or files) is hit.
        open = function(state)
          local tree = state.tree
          local ok, node = pcall(tree.get_node, tree)
          if not (ok and node) then
            return
          end
          if node.type == 'directory' and not node:is_expanded() then
            open_recursively(state)
            return
          end
          require('neo-tree.sources.filesystem.commands').open(state)
        end,
        toggle_merged_dirs = function()
          toggle_merge_single_child_dirs()
        end,
        open_nesting_config = function(state)
          local path = vim.fn.stdpath('config') .. '/lua/config/neo-tree-nesting.lua'
          local utils = require 'neo-tree.utils'
          local winid, is_neo_tree_window = utils.get_appropriate_window(state)
          if is_neo_tree_window then
            vim.cmd('new ' .. vim.fn.fnameescape(path))
            return
          end
          vim.api.nvim_set_current_win(winid)
          vim.cmd('edit ' .. vim.fn.fnameescape(path))
        end,
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

        copy_relative_path = function(state)
          local node = state.tree:get_node()
          if not node or node.type == 'message' then
            return
          end

          local path = node:get_id()
          local rel = path:sub(#state.path + 2)
          vim.fn.setreg('+', rel)
          vim.notify('Copied relative path: ' .. rel, vim.log.levels.INFO)
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
          ['<cr>'] = 'open',
          ['<S-CR>'] = 'toggle_node',
          o = { 'open', config = { expand_nested_files = true } },
          ['<leader>E'] = 'close_window',
          ['Z'] = 'expand_all_nodes',
          ['W'] = 'expand_all_subnodes',
          ['<C-W>'] = 'close_all_subnodes',
          ['<C-H>'] = 'toggle_hidden',
          gN = 'open_nesting_config',
          gE = 'toggle_merged_dirs',
          h = 'move_to_parent',
          ['['] = 'move_to_first_sibling',
          [']'] = 'move_to_last_sibling',
          -- Reassigned from neo-tree's default `H`/none so the global <S-h>/<S-l>
          -- window-navigation binds (config/binds.lua) also work in the tree window.
          H = function() vim.cmd 'wincmd h' end,
          L = function() vim.cmd 'wincmd l' end,
          y = 'system_copy',
          Y = 'copy_system_path',
          ['<C-y>'] = 'copy_relative_path',
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
      group_empty_dirs = true,
    },

    event_handlers = {
      {
        event = 'state_created',
        handler = function(state)
          if state.name == 'filesystem' then
            state.group_empty_dirs = merge_single_child_dirs
          end
        end,
      },
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
