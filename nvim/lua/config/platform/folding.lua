local region_folds = require 'lib.region-folds'

local function for_each_region_fold(bufnr, callback)
  local _, starts = region_folds.get_region_ranges(bufnr)
  for _, lnum in ipairs(starts) do
    callback(lnum)
  end
end

local function close_region_folds(bufnr)
  for_each_region_fold(bufnr, function(lnum)
    pcall(vim.cmd, ('silent keepjumps %dfoldclose'):format(lnum))
  end)
end

local function open_region_folds(bufnr)
  for_each_region_fold(bufnr, function(lnum)
    pcall(vim.cmd, ('silent keepjumps %dfoldopen!'):format(lnum))
  end)
end

vim.api.nvim_create_user_command('RegionFoldsCloseAll', function()
  close_region_folds(vim.api.nvim_get_current_buf())
end, {})

vim.api.nvim_create_user_command('RegionFoldsOpenAll', function()
  open_region_folds(vim.api.nvim_get_current_buf())
end, {})

vim.opt.fillchars:append {
  foldopen = '▾',
  foldclose = '▸',
  foldsep = ' ',
  fold = ' ',
}

vim.keymap.set('n', '<leader>zc', '<cmd>RegionFoldsCloseAll<CR>', { desc = 'Region Folds: Close All' })
vim.keymap.set('n', '<leader>zo', '<cmd>RegionFoldsOpenAll<CR>', { desc = 'Region Folds: Open All' })
