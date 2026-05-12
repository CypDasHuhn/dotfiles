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
  local node = vim.treesitter.get_node({ pos = { row, col } })
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
  if target then go(target); return end

  local p = node:parent()
  while p do
    target = first_forward(p)
    if target then go(target); return end
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
