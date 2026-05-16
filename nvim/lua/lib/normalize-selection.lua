local M = {}

function M.normalize_selection()
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
    vim.notify("normalize_selection: not in visual mode", vim.log.levels.WARN)
    return
  end

  local start_pos = vim.fn.getpos("v")
  local end_pos = vim.fn.getpos(".")
  local start_line, start_col = start_pos[2], start_pos[3] - 1
  local end_line, end_col = end_pos[2], end_pos[3]

  if start_line > end_line or (start_line == end_line and start_col > end_col) then
    start_line, end_line = end_line, start_line
    start_col, end_col = end_col - 1, start_col + 1
  end

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  if #lines == 0 then return end

  -- Extract only the selected text within the first and last lines
  lines[1] = lines[1]:sub(start_col + 1)
  lines[#lines] = lines[#lines]:sub(1, end_col - (start_line == end_line and start_col or 0))

  local text = table.concat(lines, " ")
  text = text:match("^%s*(.-)%s*$")  -- trim
  text = text:gsub("%s+", " ")       -- collapse spaces

  vim.api.nvim_buf_set_text(0, start_line - 1, start_col, end_line - 1, end_col, { text })
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
end

return M
