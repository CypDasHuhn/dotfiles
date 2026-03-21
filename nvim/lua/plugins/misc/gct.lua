return {
  'CypDasHuhn/gct',
  build = function()
    local repo = vim.fn.stdpath 'data' .. '/lazy/gct/tree-sitter-gct'
    local parser_dir = vim.fn.stdpath 'data' .. '/lazy/nvim-treesitter/parser'
    vim.fn.system {
      'gcc',
      '-o',
      repo .. '/gct.so',
      '-shared',
      '-fPIC',
      '-O2',
      '-I',
      repo .. '/src',
      repo .. '/src/parser.c',
    }
    vim.fn.system { 'cp', repo .. '/gct.so', parser_dir .. '/gct.so' }
  end,
  config = function()
    vim.filetype.add { extension = { gct = 'gct' } }

    vim.treesitter.language.register('gct', 'gct')
  end,
}
