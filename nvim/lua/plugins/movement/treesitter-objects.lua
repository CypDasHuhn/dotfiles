return {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    enabled = true,
    init = function()
        vim.g.no_plugin_maps = false
    end,
    config = function()
        require('nvim-treesitter-textobjects').setup({
            select = { lookahead = true },
            move = { set_jumps = true },
        })

        local move = require('nvim-treesitter-textobjects.move')
        local select = require('nvim-treesitter-textobjects.select')

        -- jump motions (normal mode) — lowercase=next, uppercase=prev
        local next_start = {
            ['gf'] = '@function.outer',
            ['gp'] = '@parameter.inner',
            ['gc'] = '@class.outer',
            ['gl'] = '@call.outer',
            ['gb'] = '@block.outer',
            ['gi'] = '@conditional.outer',
            ['go'] = '@loop.outer',
            ['gu'] = '@return.outer',
            ['ga'] = '@assignment.outer',
        }
        local prev_start = {
            ['gF'] = '@function.outer',
            ['gP'] = '@parameter.inner',
            ['gC'] = '@class.outer',
            ['gL'] = '@call.outer',
            ['gB'] = '@block.outer',
            ['gI'] = '@conditional.outer',
            ['gO'] = '@loop.outer',
            ['gU'] = '@return.outer',
            ['gA'] = '@assignment.outer',
        }
        local next_end = { ['gt'] = '@function.outer' }
        local prev_end = { ['gT'] = '@function.outer' }

        for key, query in pairs(next_start) do
            vim.keymap.set('n', key, function() move.goto_next_start(query) end)
        end
        for key, query in pairs(prev_start) do
            vim.keymap.set('n', key, function() move.goto_previous_start(query) end)
        end
        for key, query in pairs(next_end) do
            vim.keymap.set('n', key, function() move.goto_next_end(query) end)
        end
        for key, query in pairs(prev_end) do
            vim.keymap.set('n', key, function() move.goto_previous_end(query) end)
        end

        -- flash: bidirectional jump to any match — g<C-x> variants
        -- forward positions labeled a–z, backward positions labeled ctrl+letter
        local fj = require('lib.flash_jump')

        local function textobject_positions(query_string, use_end)
            local bufnr = vim.api.nvim_get_current_buf()
            local lang = vim.treesitter.language.get_lang(vim.bo[bufnr].filetype)
            if not lang then return {} end
            local ok, query = pcall(vim.treesitter.query.get, lang, "textobjects")
            if not ok or not query then return {} end
            local parser = vim.treesitter.get_parser(bufnr, lang)
            if not parser then return {} end
            local tree = parser:parse()[1]
            if not tree then return {} end
            local capture = query_string:match("^@(.+)")
            local positions = {}
            for id, node in query:iter_captures(tree:root(), bufnr, 0, -1) do
                if query.captures[id] == capture then
                    local row, col
                    if use_end then
                        row, col = node:end_()
                    else
                        row, col = node:start()
                    end
                    table.insert(positions, { row + 1, col })
                end
            end
            return positions
        end

        local function flash_jump(query_string, use_end)
            return function()
                local positions = textobject_positions(query_string, use_end)
                if #positions == 0 then return end
                fj.jump(positions)
            end
        end

        local flash_jumps = {
            ['g<C-f>'] = '@function.outer',
            ['g<C-p>'] = '@parameter.inner',
            ['g<C-c>'] = '@class.outer',
            ['g<C-l>'] = '@call.outer',
            ['g<C-b>'] = '@block.outer',
            ['g<C-i>'] = '@conditional.outer',
            ['g<C-o>'] = '@loop.outer',
            ['g<C-u>'] = '@return.outer',
            ['g<C-a>'] = '@assignment.outer',
        }
        for key, query in pairs(flash_jumps) do
            vim.keymap.set('n', key, flash_jump(query), { desc = 'Flash ' .. query })
        end
        vim.keymap.set('n', 'g<C-t>', flash_jump('@function.outer', true), { desc = 'Flash @function end' })

        -- select textobjects (visual + operator-pending) — unchanged
        local selections = {
            ['af'] = '@function.outer',
            ['if'] = '@function.inner',
            ['aa'] = '@parameter.outer',
            ['ia'] = '@parameter.inner',
            ['ac'] = '@class.outer',
            ['ic'] = '@class.inner',
            ['ai'] = '@conditional.outer',
            ['al'] = '@loop.outer',
        }
        for key, query in pairs(selections) do
            vim.keymap.set({ 'x', 'o' }, key, function() select.select_textobject(query, 'textobjects') end)
        end
    end,
}
