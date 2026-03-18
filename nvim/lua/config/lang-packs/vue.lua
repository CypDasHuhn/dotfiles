-- Vue / TypeScript / Frontend language pack
--
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

local vue_typescript_plugin_path = vim.fn.stdpath 'data' .. '/mason/packages/vue-language-server/node_modules/@vue/typescript-plugin'

local config = {
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
  tools = {
    'prettier',
  },

  treesitter = types,
}

for _, v in ipairs(types) do
  config.formatters[v] = { 'prettier' }
end
return config
