-- Read ./explanation.md to understand the config files!

require '.config'

vim.opt.rtp:prepend(require('lib.lazy').lazypath)

require('lazy').setup {
  { import = 'plugins' },
}
