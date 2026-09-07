return {
  'stevearc/aerial.nvim',
  event = 'VeryLazy',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  config = function(_, opts)
    local aerial = require 'aerial'
    local function is_openable(buf)
      local ft_ok, ft = pcall(vim.api.nvim_get_option_value, 'filetype', { buf = buf })
      return ft_ok
          and vim.api.nvim_buf_is_valid(buf)
          and vim.bo[buf].buftype == ''
          and ft ~= 'aerial'
          and vim.api.nvim_win_get_width(0) > 100
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
