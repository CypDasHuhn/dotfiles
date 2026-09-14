local native_usages = require 'lensline.providers.usages'
local typescript = require 'lib.lensline-typescript'

local M = {
  name = 'usages',
  event = { 'LspAttach', 'BufWritePost' },
}

local cache = {}
local pending = {}

local function roslyn_client(bufnr)
  for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr, name = 'easy_dotnet' }) do
    if client:supports_method('textDocument/codeLens', bufnr) then return client end
  end
end

local function references_by_line(lenses)
  local references = {}

  for _, lens in ipairs(lenses or {}) do
    local title = lens.command and lens.command.title
    local count = title and tonumber(title:match('(%d+)%s+[Rr]eferences'))
    local line = lens.range and lens.range.start and lens.range.start.line
    if count and line then references[line + 1] = count end
  end

  return references
end

local function refresh(bufnr, client, changedtick)
  local requested = client:request('textDocument/codeLens', {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
  }, function(err, lenses)
    vim.schedule(function()
      if not err and vim.api.nvim_buf_is_valid(bufnr) then
        cache[bufnr] = {
          changedtick = changedtick,
          references = references_by_line(lenses),
        }
      end

      local callbacks = pending[bufnr] or {}
      pending[bufnr] = nil
      for _, callback in ipairs(callbacks) do
        callback()
      end
    end)
  end, bufnr)

  if not requested then
    local callbacks = pending[bufnr] or {}
    pending[bufnr] = nil
    for _, callback in ipairs(callbacks) do
      callback()
    end
  end
end

function M.handler(bufnr, func_info, provider_config, callback)
  if typescript.handles(vim.bo[bufnr].filetype) then
    typescript.handler(bufnr, func_info, callback)
    return
  end

  if vim.bo[bufnr].filetype ~= 'cs' then
    native_usages.handler(bufnr, func_info, provider_config, callback)
    return
  end

  local client = roslyn_client(bufnr)
  if not client then
    callback(nil)
    return
  end

  local changedtick = vim.api.nvim_buf_get_changedtick(bufnr)
  local function render()
    local current = cache[bufnr]
    local count = current and current.references[func_info.line]
    if count == nil then
      callback(nil)
      return
    end

    local icon = require('lensline.utils').if_nerdfont_else('󰌹 ', '')
    local suffix = require('lensline.utils').if_nerdfont_else('', ' refs')
    callback { line = func_info.line, text = icon .. count .. suffix }
  end

  if cache[bufnr] and cache[bufnr].changedtick == changedtick then
    render()
    return
  end

  pending[bufnr] = pending[bufnr] or {}
  pending[bufnr][#pending[bufnr] + 1] = render
  if #pending[bufnr] == 1 then refresh(bufnr, client, changedtick) end
end

return M
