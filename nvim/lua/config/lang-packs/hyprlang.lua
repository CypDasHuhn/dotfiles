return {
  treesitter = { 'hyprlang' },
  filetypes = {
    pattern = {
      ['.*/hypr/.*%.conf'] = 'hyprlang',
      ['.*/hyprland/.*%.conf'] = 'hyprlang',
    },
  },
}
