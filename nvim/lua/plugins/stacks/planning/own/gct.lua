return {
  'CypDasHuhn/gct',
  dev = true,
  enabled = true,
  dir = vim.env.repos .. '/gct',
  build = 'bash -c "cd tree-sitter-gct && tree-sitter generate && cc -shared -o parser/gct.so -fPIC -I./src src/parser.c -O2"',
  init = function()
    local so_path = vim.env.repos .. '/gct/tree-sitter-gct/parser/gct.so'
    local queries_path = vim.env.repos .. '/gct/tree-sitter-gct'
    vim.filetype.add { extension = { gct = 'gct' } }
    vim.opt.rtp:prepend(queries_path)
    pcall(vim.treesitter.language.add, 'gct', { path = so_path, symbol_name = 'tree_sitter_gct' })

    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'gct',
      callback = function(ev)
        pcall(vim.treesitter.start, ev.buf, 'gct')
      end,
    })
  end,
}
