local M = {}

local original_get_node_text

local function clamp(value, minimum, maximum)
  return math.max(minimum, math.min(value, maximum))
end

local function line_length(buf, row)
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
  return line and #line or 0
end

function M.range(node, buf)
  local line_count = vim.api.nvim_buf_line_count(buf)
  local ok, start_row, start_col, end_row, end_col = pcall(node.range, node)
  if not ok then
    return 0, 0, 0, 0
  end

  start_row = clamp(start_row, 0, line_count - 1)
  end_row = clamp(end_row, 0, line_count - 1)
  if end_row < start_row then
    end_row = start_row
    end_col = start_col
  end

  start_col = clamp(start_col, 0, line_length(buf, start_row))
  end_col = clamp(end_col, 0, line_length(buf, end_row))
  if end_row == start_row and end_col < start_col then
    end_col = start_col
  end

  return start_row, start_col, end_row, end_col
end

function M.get(node, buf)
  local get = original_get_node_text or vim.treesitter.get_node_text
  local ok, text = pcall(get, node, buf)
  if ok then
    return text
  end

  local start_row, start_col, end_row, end_col = M.range(node, buf)
  local text_ok, lines = pcall(vim.api.nvim_buf_get_text, buf, start_row, start_col, end_row, end_col, {})
  if not text_ok then
    return ''
  end
  return table.concat(lines, '\n')
end

function M.install()
  if original_get_node_text then
    return
  end

  original_get_node_text = vim.treesitter.get_node_text
  vim.treesitter.get_node_text = function(node, source, opts)
    local ok, result = pcall(original_get_node_text, node, source, opts)
    if ok then
      return result
    end

    if type(source) == 'number' then
      return M.get(node, source)
    end

    error(result, 0)
  end
end

return M
