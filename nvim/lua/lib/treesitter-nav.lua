local M = {}

-- Container / expression nodes to skip when going up
-- Only skip nodes that have no keyword of their own — purely structural containers.
-- Nodes that start at a keyword (local, return, let…) are left out so they can
-- be navigated to. The same_pos guard in M.parent() handles the original
-- motivation for skipping statement/expression wrappers.
local skip_types = {
  -- Root nodes
  chunk = true,
  source_file = true,
  program = true,
  -- Block containers (start at `{` or first child, not a keyword)
  block = true,
  body = true,
  statement_block = true,
  compound_statement = true,
  -- Call/signature syntax groupers
  arguments = true,
  argument_list = true,
  parameters = true,
  parameter_list = true,
  formal_parameters = true,
  -- Expression wrappers (start at same position as their first operand)
  call_expression = true,
  function_call = true,
  method_call = true,
  binary_expression = true,
  unary_expression = true,
  parenthesized_expression = true,
  member_expression = true,
  field_expression = true,
  dot_index_expression = true,
  bracket_index_expression = true,
  subscript_expression = true,
  -- C# property internals (treat the whole property_declaration as one unit)
  modifier = true,
  nullable_type = true,
  predefined_type = true,
  accessor_list = true,
  accessor_declaration = true,
  property_declaration = true,
}

local function get_node()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]
  local node = vim.treesitter.get_node({
    pos = { row, col },
    ignore_injections = false,
  })
  if not node then return nil end
  -- Prefer the nearest named ancestor if current is a leaf anonymous node
  while node and not node:named() do
    node = node:parent()
  end
  return node
end

local function go(node)
  if not node then return false end
  local start_row, start_col = node:range()
  vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
  return true
end

local expand_stack = {}

local function section_range()
  local s = { vim.fn.line 'v' - 1, vim.fn.col 'v' - 1 }
  local e = { vim.fn.line '.' - 1, vim.fn.col '.' - 1 }
  if s[1] > e[1] or (s[1] == e[1] and s[2] > e[2]) then
    s, e = e, s
  end
  return s, e
end

local function is_visual()
  local m = vim.fn.mode()
  return m == 'v' or m == 'V' or m == '\22'
end

local function select_range(s, e)
  if is_visual() then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'nx', false)
  end
  vim.api.nvim_win_set_cursor(0, { s[1] + 1, s[2] })
  vim.cmd.normal { 'v', bang = true }
  vim.api.nvim_win_set_cursor(0, { e[1] + 1, e[2] })
end

local function last_char(row, col)
  if col > 0 then return row, col - 1 end
  if row == 0 then return 0, 0 end
  local prev = vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1]
  return row - 1, #prev - 1
end

local function same_range(a, b)
  return a[1] == b[1] and a[2] == b[2] and a[3] == b[3] and a[4] == b[4]
end

local function covers_selection(pr, cur)
  local before_or_at =
      pr[1] < cur[1] or (pr[1] == cur[1] and pr[2] <= cur[2])
  local after_or_at =
      pr[3] > cur[3] or (pr[3] == cur[3] and pr[4] >= cur[4])
  return before_or_at and after_or_at
end

local function select_node(node)
  local sr, sc, er, ec = node:range()
  local lr, lc = last_char(er, ec)
  select_range({ sr, sc }, { lr, lc })
end

function M.expand()
  local bufnr = vim.api.nvim_get_current_buf()
  local s, e
  if is_visual() then
    s, e = section_range()
  else
    local cursor = vim.api.nvim_win_get_cursor(0)
    local node = vim.treesitter.get_node({
      pos = { cursor[1] - 1, cursor[2] },
      ignore_injections = false,
    })
    while node and (not node:named() or skip_types[node:type()]) do
      node = node:parent()
    end
    if not node then return end
    expand_stack[bufnr] = {}
    select_node(node)
    return
  end

  local node = vim.treesitter.get_node({ pos = e, ignore_injections = false })
  if not node then return end
  local cur = { s[1], s[2], e[1], e[2] }
  local p = node
  local target
  while p do
    local sr, sc, er, ec = p:range()
    local pr = { sr, sc }
    local plr, plc = last_char(er, ec)
    pr[3], pr[4] = plr, plc
    if not covers_selection(pr, cur) then break end
    if not same_range(pr, cur) and not skip_types[p:type()] then
      target = pr
      break
    end
    p = p:parent()
  end
  if not target then return end
  local stack = expand_stack[bufnr]
  if not stack then
    stack = {}
    expand_stack[bufnr] = stack
  end
  stack[#stack + 1] = cur
  select_range({ target[1], target[2] }, { target[3], target[4] })
end

function M.contract()
  local s = '';
  local bufnr = vim.api.nvim_get_current_buf()
  local stack = expand_stack[bufnr]
  if not is_visual() or not stack or #stack == 0 then return end
  local prev = table.remove(stack)
  select_range({ prev[1], prev[2] }, { prev[3], prev[4] })
end

function M.parent()
  local node = get_node()
  if not node then return end
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cur_row, cur_col = cursor[1] - 1, cursor[2]
  local p = node:parent()
  while p do
    local p_row, p_col = p:range()
    local same_pos = p_row == cur_row and p_col == cur_col
    if not skip_types[p:type()] and not same_pos then
      go(p)
      return
    end
    p = p:parent()
  end
end

function M.first_child()
  local node = get_node()
  if not node then return end
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cur_row, cur_col = cursor[1] - 1, cursor[2]

  local function first_forward(from)
    for i = 0, from:named_child_count() - 1 do
      local child = from:named_child(i)
      local r, c = child:range()
      if r > cur_row or (r == cur_row and c > cur_col) then
        if not skip_types[child:type()] then
          return child
        end
        local deeper = first_forward(child)
        if deeper then return deeper end
      end
    end
  end

  local target = first_forward(node)
  if target then
    go(target); return
  end

  local p = node:parent()
  while p do
    target = first_forward(p)
    if target then
      go(target); return
    end
    p = p:parent()
  end
end

function M.next_sibling()
  local node = get_node()
  if not node then return end
  local next_node = node:next_named_sibling()
  while next_node and skip_types[next_node:type()] do
    next_node = next_node:next_named_sibling()
  end
  if next_node then
    go(next_node)
    return
  end
  -- Wrap: cycle to first non-skip sibling
  local p = node:parent()
  if p then
    local first = p:named_child(0)
    while first and skip_types[first:type()] do
      first = first:next_named_sibling()
    end
    if first and first ~= node then go(first) end
  end
end

function M.prev_sibling()
  local node = get_node()
  if not node then return end
  local prev_node = node:prev_named_sibling()
  while prev_node and skip_types[prev_node:type()] do
    prev_node = prev_node:prev_named_sibling()
  end
  if prev_node then
    go(prev_node)
    return
  end
  -- Wrap: cycle to last non-skip sibling
  local p = node:parent()
  if p then
    local count = p:named_child_count()
    local last = p:named_child(count - 1)
    while last and skip_types[last:type()] do
      last = last:prev_named_sibling()
    end
    if last and last ~= node then go(last) end
  end
end

return M
