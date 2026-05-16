-- Register parsers installed via Arch tree-sitter packages (/usr/lib/tree_sitter/)
for _, so in ipairs(vim.fn.glob('/usr/lib/tree_sitter/*.so', false, true)) do
  local lang = vim.fn.fnamemodify(so, ':t:r')
  pcall(vim.treesitter.language.add, lang, { path = so })
end

-- Enable treesitter highlighting for any buffer whose language has a parser
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('treesitter-start', { clear = true }),
  callback = function(ev)
    pcall(vim.treesitter.start, ev.buf)
  end,
})
