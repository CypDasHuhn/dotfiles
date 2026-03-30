return {
  'CypDasHuhn/gct',
  dev = true,
  enabled = false,
  dir = '/home/cyp/repos/gct',
  build = 'bash -c "cd tree-sitter-gct && tree-sitter generate && cc -shared -o parser/gct.so -fPIC -I./src src/parser.c -O2"',
  config = function()
    local ts_path = '/home/cyp/repos/gct/tree-sitter-gct'
    vim.filetype.add { extension = { gct = 'gct' } }
    vim.opt.rtp:prepend(ts_path)

    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'gct',
      callback = function()
        vim.treesitter.start()
      end,
    })
  end,
}
