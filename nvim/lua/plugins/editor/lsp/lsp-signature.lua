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
    plugin.dir .. '/lua/lsp_signature/init.lua',
    '  _LSP_SIG_CFG%.signature_result = result\n',
    '  if result.activeSignature == vim.NIL then\n'
      .. '    result.activeSignature = nil\n'
      .. '  end\n'
      .. '  if result.activeParameter == vim.NIL then\n'
      .. '    result.activeParameter = nil\n'
      .. '  end\n'
      .. '  for _, sig in ipairs(result.signatures) do\n'
      .. '    if sig.documentation == vim.NIL then\n'
      .. '      sig.documentation = nil\n'
      .. '    elseif type(sig.documentation) == \'table\' and sig.documentation.value == vim.NIL then\n'
      .. '      sig.documentation.value = nil\n'
      .. '    end\n'
      .. '    if type(sig.parameters) == \'table\' then\n'
      .. '      for _, parameter in ipairs(sig.parameters) do\n'
      .. '        if parameter.documentation == vim.NIL then\n'
      .. '          parameter.documentation = nil\n'
      .. '        elseif type(parameter.documentation) == \'table\' and parameter.documentation.value == vim.NIL then\n'
      .. '          parameter.documentation.value = nil\n'
      .. '        end\n'
      .. '      end\n'
      .. '    end\n'
      .. '  end\n'
      .. '  _LSP_SIG_CFG.signature_result = result\n',
    'null-values'
  )
  patch_source(
    plugin.dir .. '/lua/lsp_signature/helper.lua',
    'if nextParameter.documentation and #nextParameter.documentation > 0 then',
    "if type(nextParameter.documentation) == 'string' and #nextParameter.documentation > 0 then",
    'null-documentation'
  )
  patch_source(
    plugin.dir .. '/lua/lsp_signature/helper.lua',
    'helper%.remove_doc = function%(result%)\n'
      .. '  for i = 1, #result%.signatures do\n'
      .. '    log%(result%.signatures%[i%]%)\n'
      .. '    if result%.signatures%[i%] and result%.signatures%[i%]%.documentation then\n'
      .. '      if result%.signatures%[i%]%.documentation%.value then\n'
      .. '        result%.signatures%[i%]%.documentation%.value = nil\n'
      .. '      else\n'
      .. '        result%.signatures%[i%]%.documentation = nil\n'
      .. '      end\n'
      .. '    end\n'
      .. '  end\n'
      .. 'end',
    "helper.remove_doc = function(result)\n"
      .. '  for i = 1, #result.signatures do\n'
      .. '    log(result.signatures[i])\n'
      .. '    local documentation = result.signatures[i] and result.signatures[i].documentation\n'
      .. "    if type(documentation) == 'table' and documentation.value then\n"
      .. '      documentation.value = nil\n'
      .. '    elseif result.signatures[i] then\n'
      .. '      result.signatures[i].documentation = nil\n'
      .. '    end\n'
      .. '  end\n'
      .. 'end',
    'signature-null-documentation'
  )
  patch_source(
    plugin.dir .. '/lua/lsp_signature/helper.lua',
    'helper%.get_doc = function%(result%)\n'
      .. '  for i = 1, #result%.signatures do\n'
      .. '    if result%.signatures%[i%] and result%.signatures%[i%]%.documentation then\n'
      .. '      if result%.signatures%[i%]%.documentation%.value then\n'
      .. '        return result%.signatures%[i%]%.documentation%.value\n'
      .. '      else\n'
      .. '        return result%.signatures%[i%]%.documentation\n'
      .. '      end\n'
      .. '    end\n'
      .. '  end\n'
      .. 'end',
    "helper.get_doc = function(result)\n"
      .. '  for i = 1, #result.signatures do\n'
      .. '    local documentation = result.signatures[i] and result.signatures[i].documentation\n'
      .. "    if type(documentation) == 'table' then\n"
      .. '      return documentation.value\n'
      .. "    elseif type(documentation) == 'string' then\n"
      .. '      return documentation\n'
      .. '    end\n'
      .. '  end\n'
      .. 'end',
    'signature-null-documentation'
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
