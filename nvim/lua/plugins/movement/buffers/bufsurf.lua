return {
  'ton/vim-bufsurf',
  cmd = { 'BufSurfBack', 'BufSurfForward' },
  keys = {
    { '[b', '<cmd>BufSurfBack<cr>', desc = 'Buffer history back (MRU)' },
    { ']b', '<cmd>BufSurfForward<cr>', desc = 'Buffer history forward (MRU)' },
  },
}

