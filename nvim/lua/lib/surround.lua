local M = {}

local pairs_map = {
  ['{'] = { '{', '}' },
  ['}'] = { '{', '}' },
  ['('] = { '(', ')' },
  [')'] = { '(', ')' },
  ['['] = { '[', ']' },
  [']'] = { '[', ']' },
  ["'"] = { "'", "'" },
  ['"'] = { '"', '"' },
  ['`'] = { '`', '`' },
}

function M.surround_selection(char)
  local surround = pairs_map[char]
  if not surround then
    return
  end

  local open, close = surround[1], surround[2]

  local anchor = vim.fn.getpos 'v'
  local cursor = vim.fn.getpos '.'
  local al, ac = anchor[2], anchor[3]
  local cl, cc = cursor[2], cursor[3]

  local sl, sc, el, ec
  if al < cl or (al == cl and ac <= cc) then
    sl, sc = al - 1, ac - 1
    el, ec = cl - 1, cc
  else
    sl, sc = cl - 1, cc - 1
    el, ec = al - 1, ac
  end

  if vim.fn.mode() == 'V' then
    sc = 0
    ec = #vim.api.nvim_buf_get_lines(0, el, el + 1, false)[1]
  end

  vim.api.nvim_buf_set_text(0, el, ec, el, ec, { close })
  vim.api.nvim_buf_set_text(0, sl, sc, sl, sc, { open })
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
end

function M.register_keymaps()
  local chars = {
    ['{'] = 'surround with {}',
    ['('] = 'surround with ()',
    ['['] = 'surround with []',
    ["'"] = "surround with ''",
    ['"'] = 'surround with ""',
    ['`'] = 'surround with ``',
  }
  vim.keymap.set('v', 'r', '<Nop>', { desc = '+surround' })
  for char, desc in pairs(chars) do
    vim.keymap.set('v', 'r' .. char, function()
      M.surround_selection(char)
    end, { desc = desc })
  end
end

return M
