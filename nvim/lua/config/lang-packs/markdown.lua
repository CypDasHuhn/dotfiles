return {
  servers = {
    marksman = {},
    plantuml_lsp = {
      mason = false,
      cmd = {
        'plantuml-lsp',
        '-jar-path',
        'C:\\tools\\plantuml.jar',
        '-stdlib-path',
        'C:\\tools\\plantuml-stdlib\\stdlib',
      },
      filetypes = { 'plantuml' },
    },
  },
  formatters = {
    markdown = { 'markdownlint-cli2' },
  },
  linters = {},
  tools = { 'markdownlint-cli2' },
  treesitter = {},
}
