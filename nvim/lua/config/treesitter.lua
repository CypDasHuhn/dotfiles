local function register_parsers(glob_pattern)
  for _, so in ipairs(vim.fn.glob(glob_pattern, false, true)) do
    local lang = vim.fn.fnamemodify(so, ':t:r')
    pcall(vim.treesitter.language.add, lang, { path = so })
  end
end

-- Prefer parsers shipped with nvim-treesitter so they stay aligned with its queries.
register_parsers(vim.fn.stdpath 'data' .. '/lazy/nvim-treesitter/parser/*.so')

-- Fall back to parsers provided by the system.
register_parsers '/usr/lib/tree_sitter/*.so'

-- Enable treesitter highlighting for any buffer whose language has a parser
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('treesitter-start', { clear = true }),
  callback = function(ev)
    pcall(vim.treesitter.start, ev.buf)
  end,
})
