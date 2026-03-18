return {
  servers = {
    texlab = {},
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
  tools = { 'texlab', 'markdownlint-cli2' },
  treesitter = { 'latex', 'bibtex' },
}
