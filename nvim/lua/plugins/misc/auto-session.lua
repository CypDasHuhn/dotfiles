return {
    "rmagatti/auto-session",
    essential = true,
    lazy = false,

    ---enables autocomplete for opts
    ---@module "auto-session"
    ---@type AutoSession.Config
    opts = {
        suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
        close_filetypes_on_save = { "aerial", "aerial-nav", "checkhealth" },
        -- log_level = 'debug',
    },
}
