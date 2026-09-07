local function patch_null_signatures(plugin)
  local source_path = plugin.dir .. '/lua/lsp_signature/init.lua'
  local source_file, open_error = io.open(source_path, 'r')
  if not source_file then
    error('Could not read lsp_signature source: ' .. tostring(open_error))
  end

  local source = source_file:read('*a')
  source_file:close()

  if source:find('result.signatures == vim.NIL', 1, true) then
    return
  end

  local patched, replacements = source:gsub(
    'if result == nil or result%.signatures == nil or result%.signatures%[1%] == nil then',
    'if result == nil or result.signatures == vim.NIL or result.signatures == nil or result.signatures[1] == nil then'
  )
  if replacements ~= 1 then
    error('Could not apply lsp_signature null-signatures compatibility patch')
  end

  local output_file, write_error = io.open(source_path, 'w')
  if not output_file then
    error('Could not write lsp_signature source: ' .. tostring(write_error))
  end
  output_file:write(patched)
  output_file:close()
end

return {
  'ray-x/lsp_signature.nvim',
  event = 'VeryLazy',
  init = patch_null_signatures,
  build = patch_null_signatures,
  config = function()
    require('lsp_signature').setup {
      handler_opts = { border = 'rounded' },
      hint_prefix = '',
    }
  end,
}
