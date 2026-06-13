local M = {}

local folded = {}

-- Returns true when done (either folded or nothing to fold), false when ufo
-- hasn't computed fold levels yet and the caller should retry.
local function try_close_ts_nodes(bufnr, node_types)
  local ft = vim.bo[bufnr].filetype
  local lang = vim.treesitter.language.get_lang(ft) or ft
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
  if not ok or not parser then return true end

  local trees = parser:parse()
  if not trees or not trees[1] then return true end

  local node_set = {}
  for _, t in ipairs(node_types) do node_set[t] = true end

  local rows = {}
  local function walk(node)
    if node_set[node:type()] then
      local sr, _, er = node:range()
      if er > sr then
        table.insert(rows, sr + 1) -- 1-indexed
      end
    end
    for child in node:iter_children() do walk(child) end
  end
  walk(trees[1]:root())

  if #rows == 0 then return true end

  local wins = vim.fn.win_findbuf(bufnr)
  if #wins == 0 then return true end

  -- foldlevel returns 0 for every line until ufo finishes its async
  -- computation. Check one target row: if still 0, signal retry.
  local ready = false
  vim.api.nvim_win_call(wins[1], function()
    ready = vim.fn.foldlevel(rows[1]) > 0
  end)
  if not ready then return false end

  for _, win in ipairs(wins) do
    vim.api.nvim_win_call(win, function()
      local saved = vim.api.nvim_win_get_cursor(0)
      for _, row in ipairs(rows) do
        pcall(vim.api.nvim_win_set_cursor, 0, { row, 0 })
        pcall(vim.cmd, 'foldclose')
      end
      pcall(vim.api.nvim_win_set_cursor, 0, saved)
    end)
  end
  return true
end

local function schedule_fold(bufnr, node_types, attempt)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  if try_close_ts_nodes(bufnr, node_types) then return end
  if attempt < 10 then
    vim.defer_fn(function()
      schedule_fold(bufnr, node_types, attempt + 1)
    end, 50)
  end
end

-- config: { [filetype] = { 'ts_node_type', ... }, ... }
-- Only multi-line nodes can be folded; single-line nodes are silently skipped.
function M.setup(config)
  if not config or vim.tbl_isempty(config) then return end

  vim.api.nvim_create_autocmd('BufWinEnter', {
    group = vim.api.nvim_create_augroup('ts-autofold', { clear = true }),
    callback = function(ev)
      local ft = vim.bo[ev.buf].filetype
      local node_types = config[ft]
      if not node_types or folded[ev.buf] then return end
      folded[ev.buf] = true

      vim.defer_fn(function()
        schedule_fold(ev.buf, node_types, 0)
      end, 0)
    end,
  })

  vim.api.nvim_create_autocmd('BufDelete', {
    group = vim.api.nvim_create_augroup('ts-autofold-cleanup', { clear = true }),
    callback = function(ev)
      folded[ev.buf] = nil
    end,
  })
end

return M
