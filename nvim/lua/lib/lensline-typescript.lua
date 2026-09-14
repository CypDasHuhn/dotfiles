local M = {}

local filetypes = {
  javascript = true,
  javascriptreact = true,
  typescript = true,
  typescriptreact = true,
  vue = true,
}

local function client_names(filetype)
  if filetype == 'vue' then return { 'ts_ls', 'vue_ls' } end
  return { 'ts_ls' }
end

local function typescript_client(bufnr, filetype)
  for _, name in ipairs(client_names(filetype)) do
    for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr, name = name }) do
      if client:supports_method('textDocument/references', bufnr) then return client end
    end
  end
end

function M.handles(filetype)
  return filetypes[filetype] == true
end

function M.handler(bufnr, func_info, callback)
  local filetype = vim.bo[bufnr].filetype
  local client = typescript_client(bufnr, filetype)
  if not client then
    callback(nil)
    return
  end

  local requested = client:request('textDocument/references', {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    position = {
      line = func_info.line - 1,
      character = func_info.character or 0,
    },
    context = { includeDeclaration = false },
  }, function(err, references)
    vim.schedule(function()
      if err or type(references) ~= 'table' then
        callback(nil)
        return
      end

      local icon = require('lensline.utils').if_nerdfont_else('󰌹 ', '')
      local suffix = require('lensline.utils').if_nerdfont_else('', ' refs')
      callback { line = func_info.line, text = icon .. #references .. suffix }
    end)
  end, bufnr)

  if not requested then callback(nil) end
end

return M
