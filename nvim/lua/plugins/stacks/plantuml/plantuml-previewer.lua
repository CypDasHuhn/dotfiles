return {
  {
    'aklt/plantuml-syntax',
    ft = 'plantuml',
    config = function()
      -- Regenerate PNG on save so latexmk picks up the change and recompiles
      vim.api.nvim_create_autocmd('BufWritePost', {
        pattern = '*.puml',
        callback = function(ev)
          local file = ev.match
          vim.fn.jobstart({ 'plantuml', '-tpng', '-charset', 'UTF-8', file }, {
            cwd = vim.fn.fnamemodify(file, ':h'),
          })
        end,
      })
    end,
  },
  {
    'weirongxu/plantuml-previewer.vim',
    ft = 'plantuml',
    dependencies = { 'tyru/open-browser.vim' },
  },
}
