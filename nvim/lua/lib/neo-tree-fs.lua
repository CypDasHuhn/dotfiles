-- Neo-tree filesystem helpers: clipboard + undo/redo
local M = {}

local data_dir = vim.fn.stdpath('data')
local clipboard_file = data_dir .. '/neo-tree-clipboard.json'
local trash_dir = data_dir .. '/neo-tree-trash'

-- History is in-memory (instance-scoped), clipboard is file-based (shared)
local MAX_HISTORY = 50
local history = { undo = {}, redo = {} }

-- region Utilities

local function read_json(path)
  if vim.fn.filereadable(path) == 0 then
    return nil
  end
  local content = vim.fn.readfile(path)
  if #content == 0 then
    return nil
  end
  local ok, data = pcall(vim.json.decode, content[1])
  if not ok then
    return nil
  end
  return data
end

local function write_json(path, data)
  local ok, encoded = pcall(vim.json.encode, data)
  if not ok then
    return false
  end
  vim.fn.writefile({ encoded }, path)
  return true
end

local function file_exists(path)
  return vim.fn.filereadable(path) == 1 or vim.fn.isdirectory(path) == 1
end

local function ensure_trash_dir()
  if vim.fn.isdirectory(trash_dir) == 0 then
    vim.fn.mkdir(trash_dir, 'p')
  end
end

local function move_to_trash(path)
  ensure_trash_dir()
  local name = vim.fn.fnamemodify(path, ':t')
  local timestamp = os.time()
  local trash_name = timestamp .. '_' .. name
  local trash_path = trash_dir .. '/' .. trash_name
  vim.fn.rename(path, trash_path)
  return trash_path
end

local function restore_from_trash(original_path, trash_path)
  if file_exists(trash_path) then
    -- Ensure parent directory exists
    local parent = vim.fn.fnamemodify(original_path, ':h')
    if vim.fn.isdirectory(parent) == 0 then
      vim.fn.mkdir(parent, 'p')
    end
    vim.fn.rename(trash_path, original_path)
    return true
  end
  return false
end

-- endregion

-- region Clipboard

function M.collect_paths(nodes)
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

function M.write_clipboard(action, paths)
  if not paths or #paths == 0 then
    return
  end
  write_json(clipboard_file, { action = action, paths = paths })
end

function M.read_clipboard()
  local clip = read_json(clipboard_file)
  if not clip or type(clip.paths) ~= 'table' then
    return nil
  end
  if clip.action ~= 'copy' and clip.action ~= 'cut' then
    return nil
  end
  return clip
end

function M.clear_clipboard()
  vim.fn.delete(clipboard_file)
end

-- endregion

-- region History (undo/redo stacks) - instance-scoped (in-memory)

local function trim_history()
  while #history.undo > MAX_HISTORY do
    table.remove(history.undo, 1)
  end
  while #history.redo > MAX_HISTORY do
    table.remove(history.redo, 1)
  end
end

function M.push_undo(operation)
  table.insert(history.undo, operation)
  history.redo = {} -- Clear redo stack on new operation
  trim_history()
end

local function copy_path(src, dest)
  if vim.fn.isdirectory(src) == 1 then
    if vim.fn.has('win32') == 1 then
      vim.fn.system({ 'xcopy', src, dest .. '\\', '/E', '/I', '/Q' })
    else
      vim.fn.system({ 'cp', '-r', src, dest })
    end
  else
    vim.uv.fs_copyfile(src, dest)
  end
end

local function delete_path(path)
  if vim.fn.isdirectory(path) == 1 then
    vim.fn.delete(path, 'rf')
  else
    vim.fn.delete(path)
  end
end

local function reverse_operation(op)
  if op.type == 'copy' then
    -- Undo copy: delete the copied files
    for _, dest in ipairs(op.destinations or {}) do
      if file_exists(dest) then
        delete_path(dest)
      end
    end
    return true
  elseif op.type == 'move' then
    -- Undo move: move files back
    for i, dest in ipairs(op.destinations or {}) do
      local src = op.sources[i]
      if file_exists(dest) and src then
        vim.fn.rename(dest, src)
      end
    end
    return true
  elseif op.type == 'trash' then
    -- Undo trash: restore from our trash directory
    local all_restored = true
    for i, original_path in ipairs(op.paths or {}) do
      local trash_path = op.trash_paths and op.trash_paths[i]
      if trash_path then
        if not restore_from_trash(original_path, trash_path) then
          all_restored = false
        end
      else
        all_restored = false
      end
    end
    return all_restored
  elseif op.type == 'rename' then
    -- Undo rename: rename back
    if file_exists(op.new_path) then
      vim.fn.rename(op.new_path, op.old_path)
      return true
    end
    return false
  elseif op.type == 'add' then
    -- Undo add: delete the created file/directory
    if file_exists(op.path) then
      delete_path(op.path)
      return true
    end
    return false
  end
  return false
end

local function reapply_operation(op)
  if op.type == 'copy' then
    for i, src in ipairs(op.sources or {}) do
      local dest = op.destinations[i]
      if file_exists(src) and dest then
        copy_path(src, dest)
      end
    end
    return true
  elseif op.type == 'move' then
    for i, src in ipairs(op.sources or {}) do
      local dest = op.destinations[i]
      if file_exists(src) and dest then
        vim.fn.rename(src, dest)
      end
    end
    return true
  elseif op.type == 'trash' then
    -- Re-trash: move files back to trash
    local new_trash_paths = {}
    for _, path in ipairs(op.paths or {}) do
      if file_exists(path) then
        local trash_path = move_to_trash(path)
        table.insert(new_trash_paths, trash_path)
      end
    end
    op.trash_paths = new_trash_paths
    return true
  elseif op.type == 'rename' then
    if file_exists(op.old_path) then
      vim.fn.rename(op.old_path, op.new_path)
      return true
    end
    return false
  elseif op.type == 'add' then
    -- Redo add: recreate as empty file or directory
    if op.is_dir then
      vim.fn.mkdir(op.path, 'p')
    else
      vim.fn.writefile({}, op.path)
    end
    return true
  end
  return false
end

function M.undo()
  if #history.undo == 0 then
    vim.notify('Neo-tree: Nothing to undo', vim.log.levels.INFO)
    return false
  end

  local op = table.remove(history.undo)
  if reverse_operation(op) then
    table.insert(history.redo, op)
    vim.notify('Neo-tree: Undid ' .. op.type, vim.log.levels.INFO)
    require('neo-tree.sources.manager').refresh('filesystem')
    return true
  else
    -- Put it back if we couldn't reverse
    table.insert(history.undo, op)
    vim.notify('Neo-tree: Failed to undo ' .. op.type, vim.log.levels.ERROR)
    return false
  end
end

function M.redo()
  if #history.redo == 0 then
    vim.notify('Neo-tree: Nothing to redo', vim.log.levels.INFO)
    return false
  end

  local op = table.remove(history.redo)
  if reapply_operation(op) then
    table.insert(history.undo, op)
    vim.notify('Neo-tree: Redid ' .. op.type, vim.log.levels.INFO)
    require('neo-tree.sources.manager').refresh('filesystem')
    return true
  else
    table.insert(history.redo, op)
    vim.notify('Neo-tree: Failed to redo ' .. op.type, vim.log.levels.ERROR)
    return false
  end
end

-- endregion

-- region File Operations (with history tracking)

function M.paste(dest_dir)
  local clip = M.read_clipboard()
  if not clip then
    return false
  end

  local sources = {}
  local destinations = {}

  for _, src in ipairs(clip.paths) do
    local name = vim.fn.fnamemodify(src, ':t')
    local dest = dest_dir .. '/' .. name

    if clip.action == 'cut' then
      vim.fn.rename(src, dest)
    else
      copy_path(src, dest)
    end

    table.insert(sources, src)
    table.insert(destinations, dest)
  end

  -- Record operation
  M.push_undo({
    type = clip.action == 'cut' and 'move' or 'copy',
    sources = sources,
    destinations = destinations,
  })

  if clip.action == 'cut' then
    M.clear_clipboard()
  end

  return true
end

function M.trash(paths)
  if type(paths) == 'string' then
    paths = { paths }
  end

  local trashed = {}
  local trash_paths = {}
  for _, path in ipairs(paths) do
    if file_exists(path) then
      local trash_path = move_to_trash(path)
      table.insert(trashed, path)
      table.insert(trash_paths, trash_path)
    end
  end

  if #trashed > 0 then
    M.push_undo({
      type = 'trash',
      paths = trashed,
      trash_paths = trash_paths,
    })
    vim.notify('Neo-tree: Moved ' .. #trashed .. ' item(s) to trash', vim.log.levels.INFO)
    return true
  end

  return false
end


-- Track file/directory creation (for undo)
function M.track_add(path)
  if not file_exists(path) then
    return
  end
  M.push_undo({
    type = 'add',
    path = path,
    is_dir = vim.fn.isdirectory(path) == 1,
  })
end

-- Track rename (for undo)
function M.track_rename(old_path, new_path)
  M.push_undo({
    type = 'rename',
    old_path = old_path,
    new_path = new_path,
  })
end

-- endregion

return M
