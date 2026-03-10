return {
  'folke/lazydev.nvim',
  lazy = false, -- must load before lua_ls
  opts = {
    library = {
      { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      { path = 'luvit-meta/library', words = { 'vim%.uv' } },
    },
  },
}
