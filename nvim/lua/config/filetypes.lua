vim.filetype.add {
  extension = {
    puml = 'plantuml',
    plantuml = 'plantuml',
    uml = 'plantuml',
    pu = 'plantuml',
    iuml = 'plantuml',
  },
  filename = {
    justfile = 'just',
  },
  pattern = {
    ['.*/hypr/.*%.conf'] = 'hyprlang',
    ['.*/hyprland/.*%.conf'] = 'hyprlang',
    ['.*%.justfile'] = 'just',
  },
}
