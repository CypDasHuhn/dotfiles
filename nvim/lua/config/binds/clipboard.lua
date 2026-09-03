local function copy_visual_reference(absolute, include_selection)
  local file_path = vim.api.nvim_buf_get_name(0)
  if file_path == '' then
    vim.notify('Cannot copy a file reference for an unnamed buffer', vim.log.levels.WARN)
    return
  end

  local path = absolute and vim.fn.fnamemodify(file_path, ':p') or vim.fn.fnamemodify(file_path, ':.')
  local visual_start = vim.fn.line 'v'
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local first_line = math.min(visual_start, cursor_line)
  local last_line = math.max(visual_start, cursor_line)
  local reference = string.format('%s:%d-%d', path, first_line, last_line)

  if include_selection then
    local saved_register = vim.fn.getreginfo 'z'
    vim.cmd 'normal! "zy'
    local selection = vim.fn.getreg 'z'
    vim.fn.setreg('z', saved_register)
    reference = reference .. '\n' .. selection
  end

  vim.fn.setreg('+', reference)
  vim.notify('Copied ' .. reference:match '^[^\n]+', vim.log.levels.INFO)
end

vim.keymap.set('x', '<leader>y', function()
  copy_visual_reference(false, false)
end, { desc = 'Copy relative file reference' })
vim.keymap.set('x', '<leader>Y', function()
  copy_visual_reference(true, false)
end, { desc = 'Copy absolute file reference' })
vim.keymap.set('x', '<leader><C-y>', function()
  copy_visual_reference(false, true)
end, { desc = 'Copy relative reference and selection' })
