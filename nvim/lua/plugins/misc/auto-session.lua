return {
    "rmagatti/auto-session",
    essential = true,
    lazy = false,

    config = function(_, opts)
        opts.post_restore_cmds = opts.post_restore_cmds or {}
        table.insert(opts.post_restore_cmds, function()
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                local name = vim.api.nvim_buf_get_name(buf)
                if vim.startswith(name, 'sidebar-guard://') then
                    vim.api.nvim_buf_delete(buf, { force = true })
                end
            end
        end)
        require('auto-session').setup(opts)
    end,

    ---enables autocomplete for opts
    ---@module "auto-session"
    ---@type AutoSession.Config
    opts = {
        suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
        close_filetypes_on_save = { "aerial", "aerial-nav", "checkhealth" },
        -- log_level = 'debug',
    },
}
