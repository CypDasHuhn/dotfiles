return {
  'CypDasHuhn/timeline-format',
  dev = true,
  enabled = true,
  dir = vim.env.repos .. '/timeline-format',
  build = 'bash -c "cd tree-sitter-tl && tree-sitter generate && cc -shared -o parser/tl.so -fPIC -I./src src/parser.c -O2"',
  init = function()
    local so_path = vim.env.repos .. '/timeline-format/tree-sitter-tl/parser/tl.so'
    local queries_path = vim.env.repos .. '/timeline-format/tree-sitter-tl'
    vim.filetype.add { extension = { tl = 'tl' } }
    vim.opt.rtp:prepend(queries_path)
    pcall(vim.treesitter.language.add, 'tl', { path = so_path, symbol_name = 'tree_sitter_tl' })

    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'tl',
      callback = function(ev)
        pcall(vim.treesitter.start, ev.buf, 'tl')
      end,
    })
  end,
}
