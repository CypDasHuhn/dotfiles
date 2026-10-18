local function patch_source(source_path, original, replacement)
  local source_file, open_error = io.open(source_path, 'r')
  if not source_file then
    error('Could not read render-markdown source: ' .. tostring(open_error))
  end

  local source = source_file:read('*a')
  source_file:close()

  if source:find(replacement, 1, true) then
    return
  end

  local patched, replacements = source:gsub(original, replacement)
  if replacements ~= 1 then
    error('Could not apply render-markdown cwd compatibility patch')
  end

  local output_file, write_error = io.open(source_path, 'w')
  if not output_file then
    error('Could not write render-markdown source: ' .. tostring(write_error))
  end
  output_file:write(patched)
  output_file:close()
end

local function patch_render_markdown(plugin)
  patch_source(
    plugin.dir .. '/lua/render-markdown/lib/icons.lua',
    "    local filetype = vim%.filetype%.match%({ filename = 'a%.' %.%. name %}%) or name",
    "    local ok, filetype = pcall(vim.filetype.match, { filename = 'a.' .. name })\n"
      .. '    if not ok then\n'
      .. '        filetype = nil\n'
      .. '    end\n'
      .. '    filetype = filetype or name'
  )

  patch_source(
    plugin.dir .. '/lua/render-markdown/lib/node.lua',
    '    local start_row, start_col, end_row, end_col = node:range%(%)',
    "    local start_row, start_col, end_row, end_col = require('lib.ts-node-text').range(node, buf)"
  )
  patch_source(
    plugin.dir .. '/lua/render-markdown/lib/node.lua',
    '    self%.text = vim%.treesitter%.get_node_text%(node, buf%)',
    "    self.text = require('lib.ts-node-text').get(node, buf)"
  )
  patch_source(
    plugin.dir .. '/lua/render-markdown/lib/node.lua',
    '    return str%.level%(vim%.treesitter%.get_node_text%(node, self%.buf%)%)',
    "    return str.level(require('lib.ts-node-text').get(node, self.buf))"
  )
end

return {
  'MeanderingProgrammer/render-markdown.nvim',
  enabled = true,
  event = 'VeryLazy',
  init = patch_render_markdown,
  build = patch_render_markdown,
  dependencies = { 'nvim-mini/mini.nvim' },
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {
    render_modes = true,
    win_options = {
      conceallevel = { default = vim.o.conceallevel, rendered = 3 },
    },
    latex = { enabled = false },
  },
}
