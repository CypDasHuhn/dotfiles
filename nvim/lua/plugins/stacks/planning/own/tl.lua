return {
  'CypDasHuhn/timeline-format',
  dev = true,
  dir = '/home/cyp/repos/timeline',
  build = 'bash -c "cd tree-sitter-tl && tree-sitter generate && cc -shared -o parser/tl.so -fPIC -I./src src/parser.c -O2"',
  config = function()
    local ts_path = '/home/cyp/repos/timeline/tree-sitter-tl'
    vim.filetype.add { extension = { tl = 'tl' } }
    vim.opt.rtp:prepend(ts_path)

    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'tl',
      callback = function(ev)
        pcall(vim.treesitter.start, ev.buf)
      end,
    })
  end,
}
