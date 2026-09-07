return {
    'karb94/neoscroll.nvim',
    profile = 'medium',
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

        local durations = {
            medium = {
                full_page = 100,
                half_page = 50,
                line = 50,
                half_window_center = 50,
            },
            high = {
                full_page = 200,
                half_page = 100,
                line = 100,
                half_window_center = 100,
            },
        }
        local duration = durations[vim.env.NVIM_PROFILE] or durations.medium

        local keymap = {
            ['<C-u>'] = function()
                neoscroll.ctrl_u { duration = duration.half_page }
            end,
            ['<C-d>'] = function()
                neoscroll.ctrl_d { duration = duration.half_page }
            end,
            ['<C-b>'] = function()
                neoscroll.ctrl_b { duration = duration.full_page }
            end,
            ['<C-f>'] = function()
                neoscroll.ctrl_f { duration = duration.full_page }
            end,
            ['<C-y>'] = function()
                neoscroll.scroll(-0.1, { move_cursor = false, duration = duration.line })
            end,
            ['<C-e>'] = function()
                neoscroll.scroll(0.1, { move_cursor = false, duration = duration.line })
            end,
            ['zt'] = function()
                neoscroll.zt { half_win_duration = duration.half_window_center }
            end,
            ['zz'] = function()
                neoscroll.zz { half_win_duration = duration.half_window_center }
            end,
            ['zb'] = function()
                neoscroll.zb { half_win_duration = duration.half_window_center }
            end,
        }

        local modes = { 'n', 'v', 'x' }
        for key, func in pairs(keymap) do
            vim.keymap.set(modes, key, func)
        end
    end,
}
