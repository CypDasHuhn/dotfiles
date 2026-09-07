return {
  'sphamba/smear-cursor.nvim',
  profile = 'high',
  lazy = false,
  config = function()
    require('smear_cursor').setup {}
  end,
}
