return {
    'monaqa/dial.nvim',
    keys = {
        { '<C-a>',  mode = { 'n', 'x' }, desc = 'Increment' },
        { '<C-x>',  mode = { 'n', 'x' }, desc = 'Decrement' },
        { 'g<C-a>', mode = 'x',          desc = 'Increment (visual)' },
        { 'g<C-x>', mode = 'x',          desc = 'Decrement (visual)' },
    },
    config = function()
        local augend = require 'dial.augend'
        require('dial.config').augends:register_group {
            default = {
                augend.integer.alias.decimal,
                augend.integer.alias.hex,
                augend.date.alias['%Y/%m/%d'],
                augend.constant.alias.bool,
                augend.semver.alias.semver,
            },
        }

        local map = require 'dial.map'
        local set = vim.keymap.set
        set({ 'n', 'x' }, '<C-a>', map.inc_normal(), { desc = 'Increment' })
        set({ 'n', 'x' }, '<C-x>', map.dec_normal(), { desc = 'Decrement' })
        set('x', 'g<C-a>', map.inc_gvisual(), { desc = 'Increment (visual)' })
        set('x', 'g<C-x>', map.dec_gvisual(), { desc = 'Decrement (visual)' })
    end,
}
