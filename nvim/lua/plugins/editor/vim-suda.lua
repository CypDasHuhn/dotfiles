return {
    'lambdalisue/vim-suda',
    config = function()
        vim.keymap.set("n", "<leader>ws", "<cmd>SudaWrite<cr>")
    end
}
