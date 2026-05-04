return {
  servers = {
    lua_ls = {
      settings = {
        Lua = {
          completion = { callSnippet = 'Replace' },
        },
      },
    },
  },
  tools = {
    'stylua',
  },
  treesitter = { 'lua' },
}
