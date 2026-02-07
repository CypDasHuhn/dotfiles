return {
  servers = {
    ts_ls = {},
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
