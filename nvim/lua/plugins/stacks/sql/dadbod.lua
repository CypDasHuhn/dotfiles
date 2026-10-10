return {
  'kristijanhusak/vim-dadbod-ui',
  dependencies = {
    {
      'kristijanhusak/vim-dadbod-completion',
      ft = { 'sql', 'mysql', 'plsql' },
      lazy = true,
      dependencies = { 'tpope/vim-dadbod' },
    },
  },
  cmd = {
    'DBUI',
    'DBUIToggle',
    'DBUIAddConnection',
    'DBUIFindBuffer',
  },
  init = function()
    vim.g.db_ui_use_nerd_fonts = 1
    vim.g.db_ui_execute_on_save = 0

    -- Setup dadbod completion omnifunc for SQL files
    vim.api.nvim_create_autocmd('FileType', {
      pattern = { 'sql', 'mysql', 'plsql' },
      callback = function()
        vim.opt_local.omnifunc = 'vim_dadbod_completion#omni'
      end,
    })
  end,
}
