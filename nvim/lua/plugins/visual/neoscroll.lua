return {
    'karb94/neoscroll.nvim',
    enabled = true,
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
        local neoscroll = require 'neoscroll'
        neoscroll.setup {
            hide_cursor = true,
            stop_eof = true,
            respect_scrolloff = false,
            cursor_scrolls_alone = true,
            easing = 'quadratic',
        }

        local full_page_scroll_duration = 200
        local half_page_scroll_duration = 100
        local line_scroll_duration = 100
        local half_win_center_duration = 100

        local keymap = {
            ['<C-u>'] = function()
                neoscroll.ctrl_u { duration = half_page_scroll_duration }
            end,
            ['<C-d>'] = function()
                neoscroll.ctrl_d { duration = half_page_scroll_duration }
            end,
            ['<C-b>'] = function()
                neoscroll.ctrl_b { duration = full_page_scroll_duration }
            end,
            ['<C-f>'] = function()
                neoscroll.ctrl_f { duration = full_page_scroll_duration }
            end,
            ['<C-y>'] = function()
                neoscroll.scroll(-0.1, { move_cursor = false, duration = line_scroll_duration })
            end,
            ['<C-e>'] = function()
                neoscroll.scroll(0.1, { move_cursor = false, duration = line_scroll_duration })
            end,
            ['zt'] = function()
                neoscroll.zt { half_win_duration = half_win_center_duration }
            end,
            ['zz'] = function()
                neoscroll.zz { half_win_duration = half_win_center_duration }
            end,
            ['zb'] = function()
                neoscroll.zb { half_win_duration = half_win_center_duration }
            end,
        }

        local modes = { 'n', 'v', 'x' }
        for key, func in pairs(keymap) do
            vim.keymap.set(modes, key, func)
        end
    end,
}
