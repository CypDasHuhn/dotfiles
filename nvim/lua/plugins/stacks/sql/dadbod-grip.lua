return {
  'joryeugene/dadbod-grip.nvim',
  version = '*',
  init = function()
    vim.keymap.set('n', '<space>gd', ':GripConnect<CR>', { desc = 'Open database workspace (grip)' })

    vim.api.nvim_create_autocmd('BufEnter', {
      group = vim.api.nvim_create_augroup('dadbod-grip-query-pad', { clear = true }),
      pattern = 'grip://query',
      callback = function(args)
        local buf = args.buf
        vim.bo[buf].completeopt = 'menu,menuone,noinsert,popup'

        local view = require 'dadbod-grip.view'
        local tab_views = require('dadbod-grip.keymaps').TAB_VIEWS
        for n = 5, 9 do
          local view_name = tab_views[n]
          vim.keymap.set('n', tostring(n), function()
            view.close_all_floats(nil)
            local win = view.find_content_win()
            if win then
              local gbuf = vim.api.nvim_win_get_buf(win)
              vim.api.nvim_set_current_win(win)
              view.switch_view(gbuf, view_name)
            else
              local url = vim.b[buf].db or vim.g.db
              require('dadbod-grip.picker').pick_table(url, function(t)
                require('dadbod-grip').open(t, url, { view = view_name })
              end)
            end
          end, { buffer = buf, desc = 'Grip: ' .. view_name .. ' view' })
        end
      end,
    })
  end,
}
