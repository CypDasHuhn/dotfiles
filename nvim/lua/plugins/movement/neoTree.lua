-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

local function get_neotree_clipboard_file()
  return vim.fn.stdpath 'data' .. '/neo-tree-clipboard.json'
end

local function collect_paths_from_nodes(nodes)
  local paths = {}
  local seen = {}
  for _, node in ipairs(nodes or {}) do
    if node and node.type ~= 'message' then
      local path = node:get_id()
      if path and path ~= '' and not seen[path] then
        table.insert(paths, path)
        seen[path] = true
      end
    end
  end
  return paths
end

local function write_clipboard_file(action, paths)
  if not paths or #paths == 0 then
    return
  end
  local ok, data = pcall(vim.json.encode, { action = action, paths = paths })
  if not ok then
    return
  end
  vim.fn.writefile({ data }, get_neotree_clipboard_file())
end

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
      commands = {
        system_copy = function(state)
          local node = state.tree:get_node()
          if not node or node.type == 'message' then
            return
          end
          write_clipboard_file('copy', { node:get_id() })
          require('neo-tree.sources.filesystem.commands').copy_to_clipboard(state)
        end,
        system_copy_visual = function(state, selected_nodes)
          local paths = collect_paths_from_nodes(selected_nodes)
          if #paths == 0 then
            return
          end
          write_clipboard_file('copy', paths)
          require('neo-tree.sources.filesystem.commands').copy_to_clipboard_visual(state, selected_nodes)
        end,
        system_cut = function(state)
          local node = state.tree:get_node()
          if not node or node.type == 'message' then
            return
          end
          write_clipboard_file('cut', { node:get_id() })
          require('neo-tree.sources.filesystem.commands').cut_to_clipboard(state)
        end,
        system_cut_visual = function(state, selected_nodes)
          local paths = collect_paths_from_nodes(selected_nodes)
          if #paths == 0 then
            return
          end
          write_clipboard_file('cut', paths)
          require('neo-tree.sources.filesystem.commands').cut_to_clipboard_visual(state, selected_nodes)
        end,
        system_paste = function(state)
          local clipboard_file = get_neotree_clipboard_file()
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
          if not ok or not clip or type(clip.paths) ~= 'table' or (clip.action ~= 'copy' and clip.action ~= 'cut') then
            require('neo-tree.sources.filesystem.commands').paste_from_clipboard(state)
            return
          end
          local node = state.tree:get_node()
          local dest = node and node:get_id() or nil
          if not dest or dest == '' then
            require('neo-tree.sources.filesystem.commands').paste_from_clipboard(state)
            return
          end
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
      window = {
        mappings = {
          ['<leader>E'] = 'close_window',
          ['Z'] = 'expand_all_nodes',
          y = 'system_copy',
          x = 'system_cut',
          p = 'system_paste',
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
