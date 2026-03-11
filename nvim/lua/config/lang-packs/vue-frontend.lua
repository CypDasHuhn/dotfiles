-- Vue / TypeScript / Frontend language pack

local vue_typescript_plugin_path = vim.fn.stdpath 'data' .. '/mason/packages/vue-language-server/node_modules/@vue/typescript-plugin'

return {
  servers = {
    -- ts_ls handles TypeScript + JavaScript, with Vue plugin for .vue <script> blocks
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
    -- vue_ls handles template, style, and SFC structure; hybridMode lets ts_ls own the TS
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

  formatters = {
    javascript = { 'prettier' },
    typescript = { 'prettier' },
    javascriptreact = { 'prettier' },
    typescriptreact = { 'prettier' },
    vue = { 'prettier' },
    html = { 'prettier' },
    css = { 'prettier' },
    scss = { 'prettier' },
    json = { 'prettier' },
    jsonc = { 'prettier' },
    yaml = { 'prettier' },
  },

  linters = {},

  tools = {
    'prettier',
  },

  treesitter = {
    'javascript',
    'typescript',
    'tsx',
    'vue',
    'html',
    'css',
    'scss',
    'json',
    'yaml',
  },
}
