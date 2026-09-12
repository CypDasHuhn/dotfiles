return {
  'nemanjamalesija/smart-paste.nvim',
  event = 'VeryLazy',
  config = function()
    require('smart-paste').setup()
  end,
}
