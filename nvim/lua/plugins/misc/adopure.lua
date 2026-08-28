return {
    "Willem-J-an/adopure.nvim",
    dev = true,
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope.nvim",
        "sindrets/diffview.nvim"
    },
    config = function()
        vim.g.adopure = {}
    end,
}
