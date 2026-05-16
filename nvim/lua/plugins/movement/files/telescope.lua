return {
  'nvim-telescope/telescope.nvim',
  essential = true,
  event = 'VeryLazy',
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',

      build = 'make',

      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
    { 'nvim-telescope/telescope-ui-select.nvim' },

    { 'nvim-tree/nvim-web-devicons',            enabled = vim.g.have_nerd_font },
  },
  config = function()
    require('telescope').setup {
      extensions = {
        ['ui-select'] = {
          require('telescope.themes').get_dropdown(),
        },
      },
    }

    pcall(require('telescope').load_extension, 'fzf')
    pcall(require('telescope').load_extension, 'ui-select')

    local builtin = require 'telescope.builtin'
    vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
    vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
    vim.keymap.set('n', '<leader><leader>', builtin.find_files, { desc = '[S]earch [F]iles' })
    vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
    vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
    vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
    vim.keymap.set('n', '<leader>sq', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
    vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
    vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
    vim.keymap.set('n', '<leader>sb', builtin.buffers, { desc = '[S]earch in existing [B]uffers' })

    --region Directories Search
    vim.keymap.set('n', '<leader>sd', function()
      require('telescope.builtin').find_files({
        find_command = { 'fd', '--type', 'd' },
        prompt_title = 'Directories',
        attach_mappings = function(prompt_bufnr, _map)
          local actions = require('telescope.actions')
          local action_state = require('telescope.actions.state')
          actions.select_default:replace(function()
            local entry = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            if not entry then return end
            require('neo-tree.command').execute({
              action = 'focus',
              source = 'filesystem',
              reveal_file = entry.path or entry.value,
              reveal_force_cwd = false,
            })
          end)
          return true
        end,
      })
    end)
    --endregion

    --region Fuzzy search only files
    local make_entry = require('telescope.make_entry')

    vim.keymap.set('n', '<leader>sf', function()
      require('telescope.builtin').find_files({
        entry_maker = function(filepath)
          local entry = make_entry.gen_from_file({})(filepath)
          -- ordinal drives the matching, display drives what you see
          entry.ordinal = vim.fn.fnamemodify(filepath, ':t')
          return entry
        end,
      })
    end)
    --endregion

    vim.keymap.set('n', '<leader>/', function()
      builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
        winblend = 10,
        previewer = false,
      })
    end, { desc = '[/] Fuzzily search in current buffer' })

    vim.keymap.set('n', '<leader>s/', function()
      builtin.live_grep {
        grep_open_files = true,
        prompt_title = 'Live Grep in Open Files',
      }
    end, { desc = '[S]earch [/] in Open Files' })

    -- Shortcut for searching your Neovim configuration files
    vim.keymap.set('n', '<leader>sn', function()
      builtin.find_files { cwd = vim.fn.stdpath 'config' }
    end, { desc = '[S]earch [N]eovim files' })
  end,
}
