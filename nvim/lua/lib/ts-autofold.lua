local M = {}

local folded = {}

local function try_close_ts_nodes(bufnr, node_types)
  local ft = vim.bo[bufnr].filetype
  local lang = vim.treesitter.language.get_lang(ft) or ft
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
  if not ok or not parser then return true end

  local trees = parser:parse(true)
  if not trees or not trees[1] then return true end

  local node_set = {}
  for _, t in ipairs(node_types) do node_set[t] = true end

  local rows = {}
  local single_line_nodes = {}
  local function walk(node)
    if node_set[node:type()] then
      local sr, _, er = node:range()
      if er > sr then
        table.insert(rows, sr + 1) -- 1-indexed
      else
        table.insert(single_line_nodes, { start_row = sr, end_row = er })
      end
    end
    for child in node:iter_children() do walk(child) end
  end
  parser:for_each_tree(function(tree)
    walk(tree:root())
  end)

  -- Fold queries commonly group adjacent one-line imports, such as C# `using`
  -- directives. Close those groups from their first node.
  table.sort(single_line_nodes, function(a, b)
    return a.start_row < b.start_row
  end)
  local run_start, run_end, run_count
  local function close_run()
    if run_count and run_count > 1 then
      table.insert(rows, run_start + 1)
    end
  end
  for _, node in ipairs(single_line_nodes) do
    if run_end and node.start_row > run_end + 1 then
      close_run()
      run_start, run_end, run_count = nil, nil, nil
    end
    run_start = run_start or node.start_row
    run_end = node.end_row
    run_count = (run_count or 0) + 1
  end
  close_run()

  if #rows == 0 then return end

  local wins = vim.fn.win_findbuf(bufnr)
  if #wins == 0 then return end

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
end

local function schedule_fold(bufnr, node_types)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  try_close_ts_nodes(bufnr, node_types)
end

-- config: { [filetype] = { 'ts_node_type', ... }, ... }
-- Adjacent single-line nodes are folded when their parser query defines a group.
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
        schedule_fold(ev.buf, node_types)
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
