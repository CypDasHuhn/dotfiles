return {
  'kevinhwang91/nvim-ufo',
  dependencies = { 'kevinhwang91/promise-async' },
  event = { 'BufReadPost', 'BufNewFile' },
  opts = {
    close_fold_kinds_for_ft = {
      default = { 'region' },
    },
    fold_virt_text_handler = function(virt_text, lnum, end_lnum, width, truncate)
      local line = vim.api.nvim_buf_get_lines(0, lnum, lnum + 1, false)[1] or ''
      local name = line:match('region%s+(.-)%s*$')
      if name and name ~= '' then
        local suffix = ('  %d lines'):format(end_lnum - lnum)
        local avail = width - vim.fn.strdisplaywidth(suffix)
        return {
          { truncate(name, avail), 'Title' },
          { suffix, 'Comment' },
        }
      end
      return virt_text
    end,
    provider_selector = function(_, _, _)
      return function(bufnr)
        local regions = require('lib.region-folds').get_region_ranges(bufnr)
        local ok, ts_ranges = pcall(require('ufo.provider.treesitter').getFolds, bufnr)
        if ok and ts_ranges then
          return vim.list_extend(ts_ranges, regions)
        end
        return regions
      end
    end,
  },
  config = function(_, opts)
    vim.o.foldcolumn = '1'
    vim.o.foldlevel = 99
    vim.o.foldlevelstart = 99
    vim.o.foldenable = true

    local ufo = require 'ufo'
    ufo.setup(opts)

    vim.keymap.set('n', 'zR', ufo.openAllFolds, { desc = 'Open all folds' })
    vim.keymap.set('n', 'zM', ufo.closeAllFolds, { desc = 'Close all folds' })
    vim.keymap.set('n', 'zr', ufo.openFoldsExceptKinds, { desc = 'Open folds except kinds' })
    vim.keymap.set('n', 'zm', ufo.closeFoldsWith, { desc = 'Close folds with level' })
  end,
}
