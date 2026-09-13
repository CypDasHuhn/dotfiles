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
    local actions = require 'telescope.actions'

    require('telescope').setup {
      defaults = {
        mappings = {
          i = {
            ['<C-j>'] = actions.move_selection_next,
            ['<C-k>'] = actions.move_selection_previous,
          },
        },
      },
      extensions = {
        ['ui-select'] = {
          require('telescope.themes').get_dropdown(),
        },
      },
    }

    pcall(require('telescope').load_extension, 'fzf')
    pcall(require('telescope').load_extension, 'ui-select')

    local builtin = require 'telescope.builtin'
    local scopes = require 'lib.scopes'
    vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
    vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
    vim.keymap.set('n', '<leader><leader>', builtin.find_files, { desc = '[S]earch [F]iles' })
    vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
    vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
    vim.keymap.set('n', '<leader>sq', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })

    --region Scoped Search
    vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = 'Search [F]iles' })
    vim.keymap.set('n', '<leader>sfc', function() scopes.find_files 'code' end, { desc = 'Find [C]ode' })
    vim.keymap.set('n', '<leader>sft', function() scopes.find_files 'tests' end, { desc = 'Find [T]ests' })
    vim.keymap.set('n', '<leader>sfd', function() scopes.find_files 'docs' end, { desc = 'Find [D]ocs' })
    vim.keymap.set('n', '<leader>sfa', function() scopes.find_files 'all' end, { desc = 'Find [A]ll' })

    vim.keymap.set('n', '<leader>sgc', function() scopes.live_grep 'code' end, { desc = 'Grep [C]ode' })
    vim.keymap.set('n', '<leader>sgt', function() scopes.live_grep 'tests' end, { desc = 'Grep [T]ests' })
    vim.keymap.set('n', '<leader>sgd', function() scopes.live_grep 'docs' end, { desc = 'Grep [D]ocs' })
    vim.keymap.set('n', '<leader>sga', function() scopes.live_grep 'all' end, { desc = 'Grep [A]ll' })
    --endregion

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

    vim.keymap.set('n', '<leader>/', function()
      builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
        winblend = 10,
        previewer = false,
      })
    end, { desc = '[/] Fuzzily search in current buffer' })
  end,
}
