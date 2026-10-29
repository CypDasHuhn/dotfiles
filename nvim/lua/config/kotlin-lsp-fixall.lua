local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO)
end

local function code_action_client(bufnr)
  local fallback
  for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
    if client:supports_method 'textDocument/codeAction' then
      if client.name == 'kotlin_lsp' then
        return client
      end
      fallback = fallback or client
    end
  end
  return fallback
end

local function diagnostic_key(diagnostic)
  return table.concat({
    diagnostic.lnum,
    diagnostic.col,
    diagnostic.end_lnum,
    diagnostic.end_col,
    diagnostic.message or '',
  }, ':')
end

local function lsp_diagnostic(diagnostic)
  local original = diagnostic.user_data and diagnostic.user_data.lsp
  if original then
    return original
  end
  return {
    range = {
      start = { line = diagnostic.lnum, character = diagnostic.col },
      ['end'] = { line = diagnostic.end_lnum, character = diagnostic.end_col },
    },
    severity = diagnostic.severity,
    code = diagnostic.code,
    source = diagnostic.source,
    message = diagnostic.message,
  }
end

local function first_action(client, bufnr, diagnostic)
  local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
  params.textDocument = { uri = vim.uri_from_bufnr(bufnr) }
  local lsp = lsp_diagnostic(diagnostic)
  params.range = lsp.range
  params.context = {
    diagnostics = { lsp },
    triggerKind = 1,
  }

  local responses = vim.lsp.buf_request_sync(bufnr, 'textDocument/codeAction', params, 3000)
  local response = responses and responses[client.id]
  local actions = response and response.result
  if type(actions) ~= 'table' then
    return nil
  end

  for _, action in ipairs(actions) do
    if action.edit or action.command then
      return action
    end
  end
  return nil
end

local function apply_action(client, action)
  if action.edit then
    vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
  end
  if action.command then
    if client.exec_cmd then
      client:exec_cmd(action.command)
    else
      vim.lsp.buf.execute_command(action.command)
    end
  end
end

local function wait_for_diagnostics(bufnr)
  local changed = false
  local group = vim.api.nvim_create_augroup('kotlin-lsp-fixall-wait', { clear = true })
  vim.api.nvim_create_autocmd('DiagnosticChanged', {
    group = group,
    buffer = bufnr,
    once = true,
    callback = function()
      changed = true
    end,
  })
  vim.wait(1500, function()
    return changed
  end, 25)
  pcall(vim.api.nvim_del_augroup_by_id, group)
end

vim.api.nvim_create_user_command('KotlinLspFixAll', function(args)
  local bufnr = vim.api.nvim_get_current_buf()
  local client = code_action_client(bufnr)
  if not client then
    notify('KotlinLspFixAll: no code-action client attached', vim.log.levels.WARN)
    return
  end

  local max_actions = tonumber(args.args) or 25
  if max_actions < 1 then
    notify('KotlinLspFixAll: max actions must be positive', vim.log.levels.WARN)
    return
  end

  local attempted = {}
  local applied = 0
  local stopped = 'no more actions'

  for _ = 1, max_actions do
    local diagnostics = vim.diagnostic.get(bufnr)
    table.sort(diagnostics, function(a, b)
      if a.severity ~= b.severity then
        return (a.severity or 0) < (b.severity or 0)
      end
      if a.lnum ~= b.lnum then
        return a.lnum < b.lnum
      end
      return a.col < b.col
    end)

    local action
    local diagnostic
    for _, candidate in ipairs(diagnostics) do
      local key = diagnostic_key(candidate)
      if not attempted[key] then
        attempted[key] = true
        local found = first_action(client, bufnr, candidate)
        if found then
          action = found
          diagnostic = candidate
          break
        end
      end
    end

    if not action then
      stopped = 'no more actions'
      break
    end

    apply_action(client, action)
    applied = applied + 1
    notify(('KotlinLspFixAll: %d/%d %s'):format(applied, max_actions, action.title or 'applied'))
    wait_for_diagnostics(bufnr)
  end

  local remaining = #vim.diagnostic.get(bufnr)
  if remaining == 0 then
    stopped = 'done'
  elseif applied >= max_actions then
    stopped = 'max actions reached'
  end
  notify(('KotlinLspFixAll: applied %d, remaining %d (%s)'):format(applied, remaining, stopped))
end, { nargs = '?', desc = 'Apply the first quickfix for each diagnostic until none remain or the cap is hit' })
