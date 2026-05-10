local M = {}

M.enabled = vim.g.csharp_reference_codelens_enabled ~= false

local refresh_group = vim.api.nvim_create_augroup('csharp-reference-codelens', { clear = true })

local function has_easy_dotnet_client(bufnr)
  return next(vim.lsp.get_clients { bufnr = bufnr, name = 'easy_dotnet' }) ~= nil
end

local function clear(bufnr)
  vim.lsp.codelens.clear(nil, bufnr)
end

function M.refresh(bufnr)
  if not M.enabled or not has_easy_dotnet_client(bufnr) then
    clear(bufnr)
    return
  end

  vim.lsp.codelens.refresh { bufnr = bufnr }
end

function M.toggle()
  M.enabled = not M.enabled
  vim.g.csharp_reference_codelens_enabled = M.enabled

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and has_easy_dotnet_client(bufnr) then
      if M.enabled then
        M.refresh(bufnr)
      else
        clear(bufnr)
      end
    end
  end

  vim.notify(
    'C# reference CodeLens ' .. (M.enabled and 'enabled' or 'disabled'),
    vim.log.levels.INFO,
    { title = 'easy-dotnet' }
  )
end

function M.on_attach(client, bufnr)
  if client.name ~= 'easy_dotnet' then
    return
  end

  vim.api.nvim_create_autocmd({ 'BufEnter', 'InsertLeave', 'BufWritePost' }, {
    group = refresh_group,
    buffer = bufnr,
    callback = function(args)
      M.refresh(args.buf)
    end,
  })

  vim.keymap.set('n', '<leader>tc', M.toggle, {
    buffer = bufnr,
    desc = '[T]oggle C# reference [C]odeLens',
  })

  M.refresh(bufnr)
end

return M
