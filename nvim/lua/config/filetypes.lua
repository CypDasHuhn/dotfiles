vim.filetype.add {
  filename = {
    justfile = 'just',
  },
  pattern = {
    ['.*/hypr/.*%.conf'] = 'hyprlang',
    ['.*/hyprland/.*%.conf'] = 'hyprlang',
    ['.*%.justfile'] = 'just',
  },
}
