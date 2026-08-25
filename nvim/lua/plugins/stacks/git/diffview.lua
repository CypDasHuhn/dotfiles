-- Mirrors the neo-tree `Y` / `<C-y>` path-copy binds (see plugins/movement/files/neo-tree.lua)
-- for whichever file is currently focused in Diffview (file panel or diff buffers).
local function get_cur_file()
    local view = require('diffview.lib').get_current_view()
    if not view then
        return nil
    end
    return view:infer_cur_file()
end

local function copy_absolute_path()
    local file = get_cur_file()
    if not file or not file.absolute_path then
        return
    end
    vim.fn.setreg('+', file.absolute_path)
    vim.notify('Copied path: ' .. file.absolute_path, vim.log.levels.INFO)
end

local function copy_relative_path()
    local file = get_cur_file()
    if not file or not file.path then
        return
    end
    vim.fn.setreg('+', file.path)
    vim.notify('Copied relative path: ' .. file.path, vim.log.levels.INFO)
end

-- Diffs the working tree against the remote's default branch (origin/HEAD).
-- Auto-resolves origin/HEAD if it isn't already tracked locally (e.g. shallow clones).
local function open_vs_origin_head()
    vim.fn.system 'git rev-parse --verify --quiet refs/remotes/origin/HEAD'
    if vim.v.shell_error ~= 0 then
        vim.fn.system 'git remote set-head origin --auto'
    end
    if vim.v.shell_error ~= 0 then
        vim.notify('Could not resolve origin/HEAD', vim.log.levels.ERROR)
        return
    end
    vim.cmd 'DiffviewOpen origin/HEAD'
end

return {
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory', 'DiffviewOpenOriginHead' },
    keys = {
        { '<leader>gco', '<cmd>DiffviewOpen<cr>',           desc = 'Open Diffview' },
        { '<leader>gcO', '<cmd>DiffviewOpenOriginHead<cr>', desc = 'Open Diffview vs origin/HEAD' },
        { '<leader>gcx', '<cmd>DiffviewClose<cr>',          desc = 'Close Diffview' },
        { '<leader>gcr', '<cmd>DiffviewRefresh<cr>',        desc = 'Refresh Diffview' },
    },
    config = function(_, opts)
        require('diffview').setup(opts)
        vim.api.nvim_create_user_command('DiffviewOpenOriginHead', open_vs_origin_head, {
            desc = 'Open Diffview against origin/HEAD',
        })
    end,
    opts = {
        keymaps = {
            -- active in the diff buffers themselves
            view = {
                { 'n', 'Y',      copy_absolute_path, { desc = 'Copy absolute path' } },
                { 'n', '<C-y>',  copy_relative_path, { desc = 'Copy relative path' } },
            },
            -- active while focused in the file panel
            file_panel = {
                { 'n', 'Y',      copy_absolute_path, { desc = 'Copy absolute path' } },
                { 'n', '<C-y>',  copy_relative_path, { desc = 'Copy relative path' } },
            },
        },
    },
}
