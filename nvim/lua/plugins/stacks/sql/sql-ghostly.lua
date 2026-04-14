return {
  'pmouraguedes/sql-ghosty.nvim',
  ft = { 'sql' },
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
  },
  config = function()
    -- sql-ghosty hard-fails if the SQL parser is unavailable, so keep it
    -- disabled until Treesitter has the grammar installed on this machine.
    if not pcall(vim.treesitter.language.inspect, 'sql') then
      return
    end

    require('sql-ghosty').setup {}
  end,
}
