local M = {}

local filetypes = {
  javascript = true,
  javascriptreact = true,
  typescript = true,
  typescriptreact = true,
  vue = true,
}

local symbol_kinds = {
  [vim.lsp.protocol.SymbolKind.Variable] = true,
  [vim.lsp.protocol.SymbolKind.Constant] = true,
  [vim.lsp.protocol.SymbolKind.Property] = true,
}

local function client_names(filetype)
  if filetype == 'vue' then return { 'ts_ls', 'vue_ls' } end
  return { 'ts_ls' }
end

local function symbol_client(bufnr, filetype)
  for _, name in ipairs(client_names(filetype)) do
    for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr, name = name }) do
      if client:supports_method('textDocument/documentSymbol', bufnr) then return client end
    end
  end
end

local function add_symbols(symbols, result, start_line, end_line)
  for _, symbol in ipairs(symbols or {}) do
    local range = symbol.range or (symbol.location and symbol.location.range)
    if symbol_kinds[symbol.kind] and range then
      local line = range.start.line + 1
      if line >= start_line and line <= end_line then
        local selection = symbol.selectionRange or range
        result[#result + 1] = {
          line = line,
          end_line = range['end'].line + 1,
          character = selection.start.character,
          name = symbol.name,
          kind = symbol.kind,
        }
      end
    end
    add_symbols(symbol.children, result, start_line, end_line)
  end
end

function M.install()
  local lens_explorer = require 'lensline.lens_explorer'
  local discover_functions_async = lens_explorer.discover_functions_async

  lens_explorer.discover_functions_async = function(bufnr, start_line, end_line, callback)
    if not filetypes[vim.bo[bufnr].filetype] then
      discover_functions_async(bufnr, start_line, end_line, callback)
      return
    end

    discover_functions_async(bufnr, start_line, end_line, function(symbols)
      symbols = symbols or {}
      local client = symbol_client(bufnr, vim.bo[bufnr].filetype)
      if not client then
        callback(symbols)
        return
      end

      local requested = client:request('textDocument/documentSymbol', {
        textDocument = vim.lsp.util.make_text_document_params(bufnr),
      }, function(err, document_symbols)
        vim.schedule(function()
          if err or type(document_symbols) ~= 'table' then
            callback(symbols)
            return
          end

          add_symbols(document_symbols, symbols, start_line, end_line)
          lens_explorer.function_cache[bufnr] = symbols
          callback(symbols)
        end)
      end, bufnr)

      if not requested then callback(symbols) end
    end)
  end
end

return M
