return {
  'lervag/vimtex',
  ft = { 'tex', 'bib' },
  -- tag = "v2.15", -- uncomment to pin to a specific release
  init = function()
    vim.g.vimtex_view_general_viewer = 'SumatraPDF'
    vim.g.vimtex_view_general_options = '-reuse-instance -forward-search @tex @line @pdf'
    vim.g.vimtex_quickfix_mode = 0
  end,
}
