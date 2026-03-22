return {
  'CypDasHuhn/gct',
  build = 'bash -c "cd tree-sitter-gct && tree-sitter generate && cc -shared -o parser/gct.so -fPIC -I./src src/parser.c -O2"',
  config = function()
    local ts_path = vim.fn.stdpath 'data' .. '/lazy/gct/tree-sitter-gct'
    vim.fn.mkdir(ts_path .. '/parser', 'p')
    vim.filetype.add { extension = { gct = 'gct' } }
    vim.opt.rtp:append(ts_path)

    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'gct',
      callback = function()
        vim.treesitter.start()
      end,
    })
  end,
}
