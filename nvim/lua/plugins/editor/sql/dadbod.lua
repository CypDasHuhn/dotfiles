return {
  'kristijanhusak/vim-dadbod-ui',
  dependencies = {
    { 'tpope/vim-dadbod', lazy = true },
    { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql' }, lazy = true },
  },
  cmd = {
    'DBUI',
    'DBUIToggle',
    'DBUIAddConnection',
    'DBUIFindBuffer',
  },
  init = function()
    vim.keymap.set('n', '<space>gd', ':DBUI<CR>', { noremap = true, silent = true })
    vim.g.db_ui_use_nerd_fonts = 1

    -- Setup dadbod completion omnifunc for SQL files
    vim.api.nvim_create_autocmd('FileType', {
      pattern = { 'sql', 'mysql', 'plsql' },
      callback = function()
        vim.opt_local.omnifunc = 'vim_dadbod_completion#omni'
      end,
    })
  end,
}
