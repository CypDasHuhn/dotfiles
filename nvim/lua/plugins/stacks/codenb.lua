local repos = vim.env.repos or vim.fn.expand('$HOME/repos')
local repo = repos .. '/code-neighbours'

local markers = {
  '.git',
  'settings.gradle.kts',
  'settings.gradle',
  'package.json',
  '*.sln',
}

local function is_project_root(directory)
  if directory:match('/testing%-grounds/[^/]+$') then
    return true
  end
  for _, marker in ipairs(markers) do
    if marker:find('*', 1, true) then
      if #vim.fn.glob(directory .. '/' .. marker, false, true) > 0 then
        return true
      end
    else
      local path = directory .. '/' .. marker
      if vim.fn.isdirectory(path) == 1 or vim.fn.filereadable(path) == 1 then
        return true
      end
    end
  end
  return false
end

return {
  dir = repo .. '/editors/nvim',
  name = 'codenb',
  enabled = false,
  lazy = false,
  build = 'bash -c "cd '
      .. repo
      ..
      ' && (cd analysis-engine && ./gradlew :server:installDist) && (cd renderer && ./gradlew :server:installDist :web:jsBrowserDistribution)"',
  config = function()
    require('codenb').setup {
      renderer_url = 'http://127.0.0.1:8090',
      renderer_cmd = repo .. '/renderer/server/build/install/server/bin/server',
      engine_cmd = repo .. '/analysis-engine/server/build/install/server/bin/server',
      is_git = is_project_root,
      request_timeout_ms = 120000,
    }
  end,
  keys = {
    { '<leader>cn', '<cmd>CodeNbServe<cr>',     desc = 'Code Neighbours: serve' },
    { '<leader>cs', '<cmd>CodeNbStatus<cr>',    desc = 'Code Neighbours: status' },
    { '<leader>ch', '<cmd>CodeNbHere<cr>',      desc = 'Code Neighbours: file baseline' },
    { '<leader>cy', '<cmd>CodeNbSymbol<cr>',    desc = 'Code Neighbours: symbol under caret' },
    { '<leader>cd', '<cmd>CodeNbDir<cr>',       desc = 'Code Neighbours: directory baseline' },
    { '<leader>cN', '<cmd>CodeNbNamespace<cr>', desc = 'Code Neighbours: namespace baseline' },
    { '<leader>cl', '<cmd>CodeNbUrl<cr>',       desc = 'Code Neighbours: copy URL' },
    { '<leader>cg', '<cmd>CodeNbDot<cr>',       desc = 'Code Neighbours: graph dot' },
    { '<leader>cS', '<cmd>CodeNbStop<cr>',      desc = 'Code Neighbours: stop' },
  },
}
