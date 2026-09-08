return {
  'stevearc/aerial.nvim',
  event = 'VeryLazy',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  config = function(_, opts)
    local aerial = require 'aerial'
    local function in_diffview()
      local diffview = package.loaded['diffview.lib']
      return diffview and diffview.get_current_view() ~= nil
    end
    local function is_openable(buf)
      local ft_ok, ft = pcall(vim.api.nvim_get_option_value, 'filetype', { buf = buf })
      return ft_ok
          and vim.api.nvim_buf_is_valid(buf)
          and vim.bo[buf].buftype == ''
          and ft ~= 'aerial'
          and not in_diffview()
          and vim.api.nvim_win_get_width(0) > 100
    end
    local function has_editor_window()
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_is_valid(win) and vim.bo[vim.api.nvim_win_get_buf(win)].buftype == '' then
          return true
        end
      end
      return false
    end
    local function close_orphaned_aerial()
      local windows = vim.api.nvim_tabpage_list_wins(0)
      local aerial_windows = {}
      for _, win in ipairs(windows) do
        if vim.api.nvim_win_is_valid(win) and vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'aerial' then
          table.insert(aerial_windows, win)
        end
      end
      if #aerial_windows == 0 then
        return
      end
      vim.api.nvim_win_call(aerial_windows[1], function()
        vim.cmd 'quit'
      end)
    end

    aerial.setup(opts)
    local profiles = { low = 1, medium = 2, high = 3 }
    local profile = vim.env.NVIM_PROFILE or 'high'
    if profiles[profile] and profiles[profile] >= profiles.medium then
      vim.api.nvim_create_autocmd({ 'BufWinEnter', 'FileType' }, {
        group = vim.api.nvim_create_augroup('aerial-autoopen', { clear = true }),
        callback = function(args)
          if is_openable(args.buf) then
            aerial.open { focus = false }
          end
        end,
      })
      vim.api.nvim_create_autocmd('WinClosed', {
        group = vim.api.nvim_create_augroup('aerial-close-orphaned-sidebar', { clear = true }),
        callback = function()
          vim.schedule(function()
            if not has_editor_window() then
              close_orphaned_aerial()
            end
          end)
        end,
      })

      if is_openable(vim.api.nvim_get_current_buf()) then
        aerial.open { focus = false }
      end
    end
  end,
  keys = {
    { '<leader>no', '<cmd>AerialToggle!<CR>', desc = 'Toggle outline (keep focus)' },
    { '<leader>nN', '<cmd>AerialNext<CR>',    desc = 'Jump to next symbol (Aerial)' },
    { '<leader>nP', '<cmd>AerialPrev<CR>',    desc = 'Jump to previous symbol (Aerial)' },
  },
  opts = {
    backends = {
      ['_'] = { 'lsp', 'treesitter', 'markdown', 'asciidoc', 'man' },
    },
    filter_kind = false,
    lsp = {
      priority = {
        vue_ls = 20,
        ts_ls = 10,
      },
    },
    keymaps = {
      H = false,
      L = false,
    },
    autojump = true,
    highlight_on_hover = true,
  },
}
