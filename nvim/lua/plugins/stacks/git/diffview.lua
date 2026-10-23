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

    local output = vim.fn.systemlist({ 'git', '-C', path, 'rev-parse', '--show-toplevel' })
    if vim.v.shell_error ~= 0 then
        return nil
    end
    return output[1]
end

local function git(args, root)
    local command = { 'git' }
    if root then
        vim.list_extend(command, { '-C', root })
    end
    vim.list_extend(command, args)
    local result = vim.fn.systemlist(command)
    if vim.v.shell_error ~= 0 then
        return nil
    end
    return result
end

local function get_comparison_branch(root)
    local result = git({ 'config', '--local', '--get', 'diffview.comparisonBranch' }, root)
    return result and result[1] or 'origin/HEAD'
end

local function set_comparison_branch(root, branch)
    vim.fn.system({ 'git', '-C', root, 'config', '--local', 'diffview.comparisonBranch', branch })
    if vim.v.shell_error ~= 0 then
        vim.notify('Could not save comparison branch', vim.log.levels.ERROR)
        return false
    end
    return true
end

local function open_comparison(root, branch)
    if branch == 'origin/HEAD' then
        git({ 'rev-parse', '--verify', '--quiet', 'refs/remotes/origin/HEAD' }, root)
        if vim.v.shell_error ~= 0 then
            git({ 'remote', 'set-head', 'origin', '--auto' }, root)
        end
        if vim.v.shell_error ~= 0 then
            vim.notify('Could not resolve origin/HEAD', vim.log.levels.ERROR)
            return
        end
    end

    git({ 'rev-parse', '--verify', '--quiet', branch .. '^{commit}' }, root)
    if vim.v.shell_error ~= 0 then
        vim.notify('Could not resolve comparison branch: ' .. branch, vim.log.levels.ERROR)
        return
    end

    vim.cmd({ cmd = 'DiffviewOpen', args = { '-C=' .. root, branch } })
end

local function choose_comparison_branch()
    local root = get_worktree_root()
    if not root then
        vim.notify('Could not determine the current Git worktree', vim.log.levels.ERROR)
        return
    end

    local branches = { 'origin/HEAD' }
    vim.list_extend(branches, git({ 'for-each-ref', '--format=%(refname:short)', 'refs/heads' }, root) or {})

    local selected = get_comparison_branch(root)
    local default_selection_index = 1
    for index, branch in ipairs(branches) do
        if branch == selected then
            default_selection_index = index
            break
        end
    end

    local pickers = require 'telescope.pickers'
    local finders = require 'telescope.finders'
    local conf = require('telescope.config').values
    local actions = require 'telescope.actions'
    local action_state = require 'telescope.actions.state'

    pickers.new({}, {
        prompt_title = 'Diffview comparison branch',
        finder = finders.new_table({ results = branches }),
        sorter = conf.generic_sorter({}),
        default_selection_index = default_selection_index,
        attach_mappings = function(prompt_bufnr, _)
            actions.select_default:replace(function()
                local entry = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                if entry and set_comparison_branch(root, entry.value) then
                    open_comparison(root, entry.value)
                end
            end)
            return true
        end,
    }):find()
end

local function open_configured_comparison()
    local root = get_worktree_root()
    if not root then
        vim.notify('Could not determine the current Git worktree', vim.log.levels.ERROR)
        return
    end
    open_comparison(root, get_comparison_branch(root))
end

local null_windows_were_resized = false

local function resize_null_windows()
    local view = require('diffview.lib').get_current_view()
    local layout = view and view.cur_layout
    if not layout or not layout.windows then
        return
    end

    local windows = {}
    local null_windows = {}
    for _, window in ipairs(layout.windows) do
        if window:is_valid() then
            windows[#windows + 1] = window
            if window:is_nulled() then
                null_windows[#null_windows + 1] = window
            end
        end
    end

    if #null_windows == 0 then
        if null_windows_were_resized then
            local total_width = 0
            for _, window in ipairs(windows) do
                total_width = total_width + vim.api.nvim_win_get_width(window.id)
            end
            local width = math.floor(#windows > 0 and total_width / #windows or 0)
            for index, window in ipairs(windows) do
                if index < #windows then
                    vim.api.nvim_win_set_width(window.id, math.max(1, width))
                end
            end
            null_windows_were_resized = false
        end
        return
    end

    local total_width = 0
    for _, window in ipairs(windows) do
        total_width = total_width + vim.api.nvim_win_get_width(window.id)
    end

    local width = math.max(1, math.floor(total_width * 0.05))
    for _, window in ipairs(null_windows) do
        vim.api.nvim_win_set_width(window.id, width)
    end
    null_windows_were_resized = true
end

return {
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory' },
    keys = {
        { '<leader>gco', '<cmd>DiffviewOpen<cr>',           desc = 'Open Diffview' },
        { '<leader>gc<leader>', '<cmd>DiffviewOpen --selected-file=%<cr>', desc = 'Open Diffview at current file' },
        { '<leader>gcO', open_configured_comparison,         desc = 'Open configured comparison' },
        { '<leader>gcs', choose_comparison_branch,           desc = 'Select comparison branch' },
        { '<leader>gcx', '<cmd>DiffviewClose<cr>',          desc = 'Close Diffview' },
        { '<leader>gcr', '<cmd>DiffviewRefresh<cr>',        desc = 'Refresh Diffview' },
        { '<leader>gcf', '<cmd>DiffviewFileHistory<cr>',    desc = 'Open Diffview File History' },
        { '<leader>gcv', function() require('lib.review').open() end, desc = 'Review: working tree vs accepted' },
        { '<leader>gcV', function() require('lib.review').open_group() end, desc = 'Review: select group' },
        { '<leader>gcl', function() require('lib.review').log() end, desc = 'Review: accepted log' },
    },
    config = function(_, opts)
        require('diffview').setup(opts)
        local group = vim.api.nvim_create_augroup('diffview-local-layout', { clear = true })
        vim.api.nvim_create_autocmd('User', {
            group = group,
            pattern = { 'DiffviewViewPostLayout', 'DiffviewDiffBufWinEnter' },
            callback = function()
                if vim.wo.diff then
                    vim.wo.foldmethod = 'manual'
                    vim.wo.foldexpr = ''
                    vim.wo.foldenable = false
                end
                vim.schedule(resize_null_windows)
            end,
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
