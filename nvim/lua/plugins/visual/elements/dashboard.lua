local function get_header()
  local headers_dir = vim.fn.stdpath 'config' .. '/lua/plugins/visual/elements/headers/'
  local files = vim.fn.globpath(headers_dir, '*.txt', false, true)
  math.randomseed(os.time())
  local chosen = files[math.random(#files)]
  local lines = {}
  for line in io.lines(chosen) do
    table.insert(lines, line)
  end
  return lines
end
return {
  'nvimdev/dashboard-nvim',
  event = 'VimEnter',
  config = function()
    require('dashboard').setup {
      theme = 'hyper',
      config = {
        packages = { enable = true }, -- show how many plugins neovim loaded
        -- limit how many projects list, action when you press key or enter it will run this action.
        -- action can be a function type, e.g.
        -- action = func(path) vim.cmd('Telescope find_files cwd=' .. path) end
        footer = {}, -- footer
        header = get_header(),
      },
    }
  end,
  dependencies = { { 'nvim-tree/nvim-web-devicons' }, 'nvim-treesitter/nvim-treesitter' },
}
