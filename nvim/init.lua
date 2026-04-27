-- Read ./explanation.md to understand the config files!

require '.config'

vim.opt.rtp:prepend(require('lib.lazy').lazypath)

require('lazy').setup({
  { import = 'plugins' },
}, {
  pkg = {
    -- Disable package-spec ingestion (lazy.lua/pkg.json/rockspec metadata).
    -- Some plugins ship lazy.lua fragments that are not valid standalone specs.
    enabled = false,
  },
})
