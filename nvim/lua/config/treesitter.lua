local allowed = {}
local parser_dir = vim.fn.stdpath 'data' .. '/treesitter'

do
  local ok, lang_packs = pcall(require, 'config.lang-packs')
  if ok then
    if type(lang_packs.treesitter) == 'table' then
      for _, lang in ipairs(lang_packs.treesitter) do
        allowed[lang] = true
      end
    end
    if type(lang_packs.autofold) == 'table' then
      require('lib.ts-autofold').setup(lang_packs.autofold)
    end
  end
end

local function register_parsers(glob_pattern)
  for _, so in ipairs(vim.fn.glob(glob_pattern, false, true)) do
    local lang = vim.fn.fnamemodify(so, ':t:r')
    pcall(vim.treesitter.language.add, lang, { path = so })
  end
end

local function prefer_runtime_parser(lang)
  for _, path in ipairs(vim.api.nvim_get_runtime_file('parser/' .. lang .. '.so', true)) do
    if path:match('[/\\]runtime[/\\]parser[/\\]') then
      pcall(vim.treesitter.language.add, lang, { path = path })
      return
    end
  end
end

local function prefer_runtime_queries(lang, groups)
  for _, group in ipairs(groups) do
    for _, path in ipairs(vim.api.nvim_get_runtime_file('queries/' .. lang .. '/' .. group .. '.scm', true)) do
      if path:match('[/\\]runtime[/\\]queries[/\\]') then
        vim.treesitter.query.set(lang, group, table.concat(vim.fn.readfile(path), '\n'))
        break
      end
    end
  end
end

-- Prefer parsers managed explicitly by nvim-treesitter for this config.
register_parsers(parser_dir .. '/*.so')

-- Prefer parsers shipped with nvim-treesitter so they stay aligned with its queries.
register_parsers(vim.fn.stdpath 'data' .. '/lazy/nvim-treesitter/parser/*.so')

-- Fall back to parsers provided by the system.
register_parsers '/usr/lib/tree_sitter/*.so'

-- Neovim 0.12 ships markdown parsers and queries together. Force those bundled
-- parsers so markdown renderers do not pick up stale user-installed parser builds.
prefer_runtime_parser 'markdown'
prefer_runtime_parser 'markdown_inline'
prefer_runtime_queries('markdown', { 'folds', 'highlights', 'injections' })
prefer_runtime_queries('markdown_inline', { 'highlights', 'injections' })

-- Enable treesitter highlighting only for languages opted into via lang packs.
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('treesitter-start', { clear = true }),
  callback = function(ev)
    local filetype = vim.bo[ev.buf].filetype
    local lang = vim.treesitter.language.get_lang(filetype) or filetype
    if not allowed[lang] then
      return
    end

    pcall(vim.treesitter.start, ev.buf, lang)
  end,
})
