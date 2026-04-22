return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'master',
  event = { 'BufReadPost', 'BufNewFile' },
  build = ':TSUpdate',
  config = function()
    local langs = require '.config.lang-packs.init'
    local own_parsers = { tl = true, gct = true }

    local parsers = vim.list_extend(
      { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' },
      langs.treesitter
    )
    parsers = vim.tbl_filter(function(p) return p ~= 'latex' end, parsers)

    local function enable_indent(bufnr)
      vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end

    local function enable_treesitter(bufnr)
      if pcall(vim.treesitter.start, bufnr) then
        enable_indent(bufnr)
      end
    end

    -- nvim-treesitter v1+ dropped `nvim-treesitter.configs`; parsers are managed via TSInstall/TSUpdate.
    local ok_config, ts_config = pcall(require, 'nvim-treesitter.config')
    local ok_install, ts_install = pcall(require, 'nvim-treesitter.install')
    if ok_config and ok_install then
      local installed = ts_config.get_installed('parsers')
      local installed_set = {}
      for _, lang in ipairs(installed or {}) do
        installed_set[lang] = true
      end

      local missing = {}
      for _, lang in ipairs(parsers) do
        if not own_parsers[lang] and not installed_set[lang] then
          table.insert(missing, lang)
        end
      end

      if #missing > 0 then
        -- Fire-and-forget; shows a summary and avoids blocking startup.
        vim.schedule(function()
          pcall(ts_install.install, missing, { summary = true })
        end)
      end
    end

    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('nvim-treesitter-start', { clear = true }),
      callback = function(ev)
        enable_treesitter(ev.buf)
      end,
    })
  end,
}
