local function patch_source(source_path, original, replacement, patch_name)
  local source_file, open_error = io.open(source_path, 'r')
  if not source_file then
    error('Could not read lsp_signature source: ' .. tostring(open_error))
  end

  local source = source_file:read('*a')
  source_file:close()

  if source:find(replacement, 1, true) then
    return
  end

  local patched, replacements = source:gsub(original, replacement)
  if replacements ~= 1 then
    error('Could not apply lsp_signature ' .. patch_name .. ' compatibility patch')
  end

  local output_file, write_error = io.open(source_path, 'w')
  if not output_file then
    error('Could not write lsp_signature source: ' .. tostring(write_error))
  end
  output_file:write(patched)
  output_file:close()
end

local function patch_lsp_signature(plugin)
  patch_source(
    plugin.dir .. '/lua/lsp_signature/init.lua',
    'if result == nil or result%.signatures == nil or result%.signatures%[1%] == nil then',
    'if result == nil or result.signatures == vim.NIL or result.signatures == nil or result.signatures[1] == nil then',
    'null-signatures'
  )
  patch_source(
    plugin.dir .. '/lua/lsp_signature/helper.lua',
    'if nextParameter.documentation and #nextParameter.documentation > 0 then',
    "if type(nextParameter.documentation) == 'string' and #nextParameter.documentation > 0 then",
    'null-documentation'
  )
end

return {
  'ray-x/lsp_signature.nvim',
  event = 'VeryLazy',
  init = patch_lsp_signature,
  build = patch_lsp_signature,
  config = function()
    require('lsp_signature').setup {
      handler_opts = { border = 'rounded' },
      hint_prefix = '',
    }
  end,
}
