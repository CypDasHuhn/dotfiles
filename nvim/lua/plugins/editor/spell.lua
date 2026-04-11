return {
    -- spell checking disabled; revisit later

    --[[
    {
        'ravibrock/spellwarn.nvim',
        event = 'VeryLazy',
        opts = {
            ft_config = {
                markdown = 'iter',
                tex = 'iter',
            },
            ft_default = false,
            severity = {
                spellbad   = 'WARN',
                spellcap   = 'HINT',
                spelllocal = 'HINT',
                spellrare  = false,
            },
        },
        config = function(_, opts)
            vim.opt.spell = true
            vim.opt.spelllang = { 'en', 'de' }

            -- auto-download missing spell files without prompting
            local function ensure_spell_file(lang)
                local dir = vim.fn.stdpath('data') .. '/site/spell/'
                local spl = dir .. lang .. '.utf-8.spl'
                if vim.fn.filereadable(spl) == 1 then return end
                vim.fn.mkdir(dir, 'p')
                local url = 'https://ftp.nluug.nl/pub/vim/runtime/spell/' .. lang .. '.utf-8.spl'
                vim.notify('Downloading spell file: ' .. lang, vim.log.levels.INFO)
                vim.fn.system({ 'curl', '-sL', '-o', spl, url })
            end

            for _, lang in ipairs({ 'en', 'de' }) do
                ensure_spell_file(lang)
            end

            require('spellwarn').setup(opts)

            --[[
      vim.keymap.set('n', '<leader>ts', function()
        local ns = vim.api.nvim_get_namespaces()['spellwarn']
        if ns then
          vim.diagnostic.enable(not vim.diagnostic.is_enabled({ ns_id = ns }), { ns_id = ns })
        end
      end, { desc = '[T]oggle [S]pell' })
      --]]
        end,
    },

    {
        'kamykn/spelunker.vim',
        event = 'VeryLazy',
        init = function()
            vim.g.spelunker_check_type = 2     -- check on CursorHold, not full buffer
            vim.g.spelunker_highlight_type = 2 -- highlight only bad words, not all
            vim.g.spelunker_disable_backquoted_words = 1
            vim.g.spelunker_disable_uri_checking = 1
            vim.g.spelunker_disable_account_name_checking = 1
            vim.g.spelunker_disable_email_checking = 1
            -- disable in files where spellwarn handles it
            vim.g.spelunker_disable_auto_group = 1
        end,
        config = function()
            vim.api.nvim_create_autocmd('FileType', {
                pattern = { 'markdown', 'tex' },
                callback = function()
                    vim.b.spelunker_disable = 1
                end,
            })
        end,
    },
    --]]
}
