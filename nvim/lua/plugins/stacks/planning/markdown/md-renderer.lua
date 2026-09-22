return {
    'MeanderingProgrammer/render-markdown.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-mini/mini.nvim' },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
        render_modes = true,
        latex = {
            enabled = true,
            converter = { 'latex2text', 'utftex' },
            inline = true,
            block = true,
            render_modes = true,
        },
    },
}
