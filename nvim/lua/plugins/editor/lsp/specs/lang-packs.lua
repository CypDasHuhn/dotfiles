local langs = require '.config.lang-packs.init'

return {
  'neovim/nvim-lspconfig',
  opts = function(_, opts)
    opts.servers = vim.tbl_deep_extend('force', opts.servers or {}, langs.servers or {})
    opts.server_aliases = vim.tbl_extend('force', opts.server_aliases or {}, langs.server_aliases or {})
    opts.tools = opts.tools or {}
    vim.list_extend(opts.tools, langs.tools or {})
  end,
}
