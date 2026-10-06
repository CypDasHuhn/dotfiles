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
--

-- Diffs the working tree against the remote's default branch (origin/HEAD).
-- Auto-resolves origin/HEAD if it isn't already tracked locally (e.g. shallow clones).
local function get_worktree_root()
    local diffview = package.loaded['diffview.lib']
    if diffview then
        local view = diffview.get_current_view()
        local toplevel = view
            and view.adapter
            and view.adapter.ctx
            and view.adapter.ctx.toplevel
        if toplevel then
            return toplevel
        end
    end

    local path = vim.api.nvim_buf_get_name(0)
    if vim.bo.buftype ~= '' or path == '' then
        path = vim.fn.getcwd()
    end
    path = vim.fn.fnamemodify(path, ':p')
    if vim.fn.isdirectory(path) == 0 then
        path = vim.fn.fnamemodify(path, ':h')
    end

    local output = vim.fn.systemlist({
        'git',
        '-C',
        path,
        'rev-parse',
        '--show-toplevel',
    })
    if vim.v.shell_error ~= 0 then
        return nil
    end
    return output[1]
end

local function open_vs_origin_head()
    local root = get_worktree_root()
    if not root then
        vim.notify('Could not determine the current Git worktree', vim.log.levels.ERROR)
        return
    end

    vim.fn.systemlist({
        'git',
        '-C',
        root,
        'rev-parse',
        '--verify',
        '--quiet',
        'refs/remotes/origin/HEAD',
    })
    if vim.v.shell_error ~= 0 then
        vim.fn.systemlist({ 'git', '-C', root, 'remote', 'set-head', 'origin', '--auto' })
    end
    if vim.v.shell_error ~= 0 then
        vim.notify('Could not resolve origin/HEAD', vim.log.levels.ERROR)
        return
    end
    vim.cmd({ cmd = 'DiffviewOpen', args = { '-C=' .. root, 'origin/HEAD' } })
end

return {
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory', 'DiffviewOpenOriginHead' },
    keys = {
        { '<leader>gco', '<cmd>DiffviewOpen<cr>',           desc = 'Open Diffview' },
        { '<leader>gc<leader>', '<cmd>DiffviewOpen --selected-file=%<cr>', desc = 'Open Diffview at current file' },
        { '<leader>gcO', '<cmd>DiffviewOpenOriginHead<cr>', desc = 'Open Diffview vs origin/HEAD' },
        { '<leader>gcx', '<cmd>DiffviewClose<cr>',          desc = 'Close Diffview' },
        { '<leader>gcr', '<cmd>DiffviewRefresh<cr>',        desc = 'Refresh Diffview' },
        { '<leader>gcf', '<cmd>DiffviewFileHistory<cr>',    desc = 'Open Diffview File History' },
        { '<leader>gcv', function() require('lib.review').open() end, desc = 'Review: working tree vs accepted' },
        { '<leader>gcl', function() require('lib.review').log() end, desc = 'Review: accepted log' },
    },
    config = function(_, opts)
        require('diffview').setup(opts)
        vim.api.nvim_create_user_command('DiffviewOpenOriginHead', open_vs_origin_head, {
            desc = 'Open Diffview against origin/HEAD',
        })
    end,
    opts = function()
        local actions = require 'diffview.actions'
        return {
            keymaps = {
                -- active in the diff buffers themselves
                view = {
                    { 'n', 'Y',     copy_absolute_path, { desc = 'Copy absolute path' } },
                    { 'n', '<C-y>', copy_relative_path, { desc = 'Copy relative path' } },
                    { 'n', 'A',     function() require('lib.review').accept_current() end, { desc = 'Accept entry' } },
                    { 'n', 'gA',    function() require('lib.review').undo_current() end,   { desc = 'Un-accept last entry' } },
                },
                -- active while focused in the file panel
                -- `L` is freed up (moved to `gL`) so <S-l>/<S-h> window navigation works here too.
                file_panel = {
                    { 'n', 'Y',     copy_absolute_path,      { desc = 'Copy absolute path' } },
                    { 'n', '<C-y>', copy_relative_path,      { desc = 'Copy relative path' } },
                    { 'n', 'L',     false },
                    { 'n', 'gL',    actions.open_commit_log, { desc = 'Open the commit log panel' } },
                    { 'n', 'A',     function() require('lib.review').accept_current() end, { desc = 'Accept entry' } },
                    { 'n', 'gA',    function() require('lib.review').undo_current() end,   { desc = 'Un-accept last entry' } },
                },
                file_history_panel = {
                    { 'n', 'L',  false },
                    { 'n', 'gL', actions.open_commit_log, { desc = 'Show commit details' } },
                },
            },
        }
    end,
}
