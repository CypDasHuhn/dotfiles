-- Show colors inline in the dec (#FF0000)
return {
  'brenoprata10/nvim-highlight-colors',
  event = { 'BufReadPre', 'BufNewFile' },
  opts = {
    render = 'background',
  },
}
