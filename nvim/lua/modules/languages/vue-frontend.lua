-- Vue / TypeScript / Frontend language pack

local vue_language_server_path = vim.fn.expand '$MASON/packages/vue-language-server/node_modules/@vue/language-server'

return {
  servers = {
    -- vtsls handles TypeScript + JavaScript, with Vue plugin for .vue <script> blocks
    vtsls = {
      filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
      settings = {
        vtsls = {
          tsserver = {
            globalPlugins = {
              {
                name = '@vue/typescript-plugin',
                location = vue_language_server_path,
                languages = { 'vue' },
                configNamespace = 'typescript',
              },
            },
          },
        },
      },
    },
    -- vue_ls handles template, style, and SFC structure; hybridMode lets vtsls own the TS
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
