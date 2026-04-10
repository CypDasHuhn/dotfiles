return {
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory' },
    keys = {
        { '<leader>gco', '<cmd>DiffviewOpen<cr>',    desc = 'Open Diffview' },
        { '<leader>gcx', '<cmd>DiffviewClose<cr>',   desc = 'Close Diffview' },
        { '<leader>gcr', '<cmd>DiffviewRefresh<cr>', desc = 'Refresh Diffview' },
    },
}
