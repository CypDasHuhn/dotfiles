return {
  'oribarilan/lensline.nvim',
  event = 'LspAttach',
  opts = function()
    local providers = require 'lensline.providers'
    providers.available_providers.detekt = require 'lib.lensline-kotlin'

    return {
      provider_timeout_ms = 15000,
      profiles = {
        {
          name = 'default',
          providers = {
            { name = 'usages', enabled = true },
            { name = 'detekt', enabled = true, event = { 'BufWritePost' } },
            { name = 'last_author', enabled = true },
          },
        },
      },
    }
  end,
}
