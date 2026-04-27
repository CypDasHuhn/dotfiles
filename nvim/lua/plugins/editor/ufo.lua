return {
  'kevinhwang91/nvim-ufo',
  dependencies = { 'kevinhwang91/promise-async' },
  event = { 'BufReadPost', 'BufNewFile' },
  opts = {
    close_fold_kinds_for_ft = {
      default = { 'region' },
    },
    provider_selector = function(_, _, _)
      return function(bufnr)
        local regions = require('lib.region-folds').get_region_ranges(bufnr)
        return require('ufo.provider.treesitter').getFolds(bufnr):then(function(ts_ranges)
          return vim.list_extend(ts_ranges or {}, regions)
        end):catch(function()
          return regions
        end
        return vim.list_extend(ts_ranges or {}, regions)
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
