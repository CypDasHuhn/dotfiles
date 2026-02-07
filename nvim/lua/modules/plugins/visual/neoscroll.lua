return {
  'karb94/neoscroll.nvim',
  config = function()
    require('neoscroll').setup {
      mappings = { '<C-u>', '<C-d>', '<C-b>', '<C-f>', '<C-y>', '<C-e>', 'zt', 'zz', 'zb' },
      hide_cursor = true,
      stop_eof = true,
      respect_scrolloff = false,
      cursor_scrolls_alone = true,
      easing_function = 'quadratic', -- Default easing function
      pre_hook = nil,
      post_hook = nil,
    }

    local t = {}
    t['<C-u>'] = { 'scroll', { '-vim.wo.scroll', 'true', '100' } }
    t['<C-d>'] = { 'scroll', { 'vim.wo.scroll', 'true', '100' } }
    require('neoscroll.config').set_mappings(t)
  end,
}
