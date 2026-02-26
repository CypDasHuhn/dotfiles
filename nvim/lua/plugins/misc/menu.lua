return {
  { 'nvzone/volt', lazy = true },
  {
    'nvzone/menu',
    lazy = true,
    keys = {
      {
        '<C-t>',
        function()
          require('menu').open('default')
        end,
        desc = 'Open menu',
      },
      {
        '<RightMouse>',
        function()
          require('menu.utils').delete_old_menus()
          vim.cmd.exec '"normal! \\<RightMouse>"'

          local buf = vim.api.nvim_win_get_buf(vim.fn.getmousepos().winid)
          local options = vim.bo[buf].ft == 'neo-tree' and 'nvimtree' or 'default'
          require('menu').open(options, { mouse = true })
        end,
        mode = { 'n', 'v' },
        desc = 'Right click menu',
      },
    },
  },
}
