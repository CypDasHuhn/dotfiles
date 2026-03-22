-- Vue / TypeScript / Frontend language pack

local types = {
  'javascript',
  'typescript',
  'tsx',
  'vue',
  'html',
  'css',
  'scss',
  'json',
  'yaml',
}

local function formatter_for_all(filetypes, formatter)
  local result = {}
  for _, ft in ipairs(filetypes) do
    result[ft] = formatter
  end
  return result
end

local vue_typescript_plugin_path = vim.fn.stdpath 'data' .. '/mason/packages/vue-language-server/node_modules/@vue/typescript-plugin'

return {
  servers = {
    ts_ls = {
      filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
      init_options = {
        plugins = {
          {
            name = '@vue/typescript-plugin',
            location = vue_typescript_plugin_path,
            languages = { 'javascript', 'typescript', 'vue' },
          },
        },
      },
      settings = {
        implicitProjectConfiguration = {
          checkJs = false,
        },
      },
    },
    vue_ls = {
      init_options = {
        vue = {
          hybridMode = true,
        },
      },
    },
    tailwindcss = {},
    eslint = {},
  },
  formatters = formatter_for_all(types, { 'prettier' }),
  tools = { 'prettier' },
  treesitter = types,
}
