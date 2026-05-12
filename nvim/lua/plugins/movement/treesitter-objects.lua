return {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    enabled = true,
    init = function()
        -- Disable entire built-in ftplugin mappings to avoid conflicts.
        -- See https://github.com/neovim/neovim/tree/master/runtime/ftplugin for built-in ftplugins.
        vim.g.no_plugin_maps = false

        -- Or, disable per filetype (add as you like)
        -- vim.g.no_python_maps = true
        -- vim.g.no_ruby_maps = true
        -- vim.g.no_rust_maps = true
        -- vim.g.no_go_maps = true
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
        local next_end = {
            ['gt'] = '@function.outer',
        }
        local prev_end = {
            ['gT'] = '@function.outer',
        }

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

        -- select textobjects (visual + operator-pending)
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
