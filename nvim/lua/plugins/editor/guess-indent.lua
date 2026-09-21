return {
  'NMAC427/guess-indent.nvim',
  event = { 'BufReadPost', 'BufNewFile' },
  config = function()
    require('guess-indent').setup {
      -- Prefer .editorconfig when present; fall back to detection otherwise.
      override_editorconfig = false,
    }
  end,
}
