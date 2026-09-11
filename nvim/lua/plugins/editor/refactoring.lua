local ts = vim.treesitter
local iter = vim.iter

-- region Kotlin type helpers
local literal_types = {
  string_literal = 'String',
  character_literal = 'Char',
  integer_literal = 'Int',
  long_literal = 'Long',
  real_literal = 'Double',
  float_literal = 'Float',
  boolean_literal = 'Boolean',
  hex_literal = 'Int',
  bin_literal = 'Int',
  unsigned_literal = 'UInt',
}

local function node_text(node, source)
  if not node then return nil end
  return ts.get_node_text(node, source)
end

local function infer_type(node, source)
  if not node then return nil end
  local kind = node:type()
  if literal_types[kind] then return literal_types[kind] end

  if kind == 'parenthesized_expression' then
    return infer_type(node:named_child(0), source)
  end

  if kind == 'additive_expression' then
    for child in node:iter_children() do
      local child_kind = child:type()
      if child_kind == 'string_literal' or child_kind == 'interpolated_expression' then
        return 'String'
      end
    end
    return 'Int'
  end

  if kind == 'multiplicative_expression' then return 'Int' end

  if
    kind == 'comparison_expression'
    or kind == 'equality_expression'
    or kind == 'conjunction_expression'
    or kind == 'disjunction_expression'
    or kind == 'check_expression'
  then
    return 'Boolean'
  end

  if kind == 'prefix_expression' then
    local text = node_text(node, source)
    return text and text:sub(1, 1) == '!' and 'Boolean' or 'Int'
  end

  if kind == 'elvis_expression' then
    return infer_type(node:named_child(0), source)
  end

  if kind == 'when_expression' then
    local types = {}
    for entry in node:iter_children() do
      if entry:type() == 'when_entry' then
        local result = entry:named_child(entry:named_child_count() - 1)
        if result and result:type() == 'control_structure_body' then
          result = result:named_child(result:named_child_count() - 1)
        end
        local inferred = infer_type(result, source)
        if not inferred then return nil end
        types[inferred] = true
      end
    end
    local keys = vim.tbl_keys(types)
    return #keys == 1 and keys[1] or nil
  end

  return nil
end

-- region LSP type fallback
local hover_cache = {}

local function parse_hover_type(text, name)
  for line in text:gmatch '[^\r\n]+' do
    local ty = line:match(name .. '%s*:%s*([%w_%.%<%>%[%]%?%,%s]+)')
    if ty then
      ty = vim.trim(ty):gsub('[,%s]+$', '')
      if ty ~= '' and ty ~= 'ERROR' then return ty end
    end
  end
  return nil
end

---@param bufnr integer
---@param node TSNode
---@return string?
local function lsp_hover_type(bufnr, node)
  if #vim.lsp.get_clients { bufnr = bufnr, method = 'textDocument/hover' } == 0 then return nil end

  local row, col = node:start()
  local key = ('%d:%d:%d'):format(bufnr, row, col)
  if hover_cache[key] then return hover_cache[key] end

  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ''
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    position = { line = row, character = vim.str_utfindex(line, 'utf-16', col) },
  }
  local ok, responses = pcall(vim.lsp.buf_request_sync, bufnr, 'textDocument/hover', params, 1000)
  if not ok or type(responses) ~= 'table' then return nil end

  local name = ts.get_node_text(node, bufnr)
  for _, response in pairs(responses) do
    local contents = response.result and response.result.contents
    local text = type(contents) == 'table' and contents.value or contents
    if type(text) == 'string' then
      local ty = parse_hover_type(text, name)
      if ty then
        hover_cache[key] = ty
        return ty
      end
    end
  end

  return nil
end
-- endregion

---@param metadata vim.treesitter.query.TSMetadata
---@param match table<integer, TSNode[]>
---@param type_id integer?
---@param value_id integer?
---@param identifier_id integer?
---@param source integer|string
local function set_types(metadata, match, type_id, value_id, identifier_id, source)
  local identifiers = identifier_id and match[identifier_id] or nil
  if not identifiers or #identifiers == 0 then return end

  local type_nodes = type_id and match[type_id] or nil
  local value_nodes = value_id and match[value_id] or nil
  if type_nodes and #type_nodes == 0 then type_nodes = nil end
  if value_nodes and #value_nodes == 0 then value_nodes = nil end

  local bufnr = type(source) == 'number' and source or nil
  local types = {}
  for i = 1, #identifiers do
    local explicit = type_nodes and (type_nodes[i] or type_nodes[1])
    local value = value_nodes and (value_nodes[i] or value_nodes[1])
    local ty = node_text(explicit, source) or infer_type(value, source)
    if not ty and bufnr then ty = lsp_hover_type(bufnr, identifiers[i]) end
    types[i] = ty
  end
  metadata.types = types
end

ts.query.add_directive('kotlin-set-type!', function(match, _, source, predicate, metadata)
  set_types(metadata, match, predicate[2], nil, predicate[3], source)
end, { force = true, all = true })

ts.query.add_directive('kotlin-decl-type!', function(match, _, source, predicate, metadata)
  set_types(metadata, match, predicate[2], predicate[3], predicate[4], source)
end, { force = true, all = true })
-- endregion

-- region Kotlin code generation
local function kotlin_arg_list(args)
  return iter(args)
    :map(function(v)
      return ('%s: %s'):format(v.identifier, v.type or 'Any')
    end)
    :join ', '
end

local kotlin_code_generation = {
  function_declaration = {
    kotlin = function(opts)
      local return_type = #opts.return_values == 0 and 'Unit' or (opts.return_values[1].type or 'Any')
      local visibility = opts.method and 'private ' or ''
      return ([[
%sfun %s(%s): %s {
%s
}]]):format(visibility, opts.name, kotlin_arg_list(opts.args), return_type, opts.body)
    end,
  },
  function_call = {
    kotlin = function(opts)
      local args = iter(opts.args)
        :map(function(v)
          return v.identifier
        end)
        :join ', '
      if #opts.return_values == 0 then return ('%s(%s)'):format(opts.name, args) end
      if #opts.return_values == 1 then
        return ('val %s = %s(%s)'):format(opts.return_values[1].identifier, opts.name, args)
      end
      vim.notify(
        'The extracted function has multiple return values, which Kotlin does not support directly',
        vim.log.levels.WARN,
        { title = 'refactoring.nvim' }
      )
      return ('val %s = %s(%s)'):format(opts.return_values[1].identifier, opts.name, args)
    end,
  },
  return_statement = {
    kotlin = function(opts)
      return ('\n\nreturn %s'):format(opts.return_values[1].identifier)
    end,
  },
}
-- endregion

return {
  'ThePrimeagen/refactoring.nvim',
  dependencies = { 'lewis6991/async.nvim' },
  keys = {
    {
      '<leader>rf',
      mode = { 'n', 'x' },
      function() return require('refactoring').extract_func() end,
      expr = true,
      desc = 'Extract function',
    },
  },
  config = function()
    local async_modules = {
      'refactoring',
      'refactoring.config',
      'refactoring.command',
      'refactoring.utils',
      'refactoring.refactor.extract_func',
      'refactoring.refactor.extract_var',
      'refactoring.refactor.inline_func',
      'refactoring.refactor.inline_var',
      'refactoring.debug',
      'refactoring.debug.print_var',
      'refactoring.debug.print_loc',
      'refactoring.debug.print_exp',
      'refactoring.debug.cleanup',
    }

    local promise_async = package.loaded['async']
    if not promise_async then
      local dir = vim.fn.stdpath 'data' .. '/lazy/promise-async'
      local path = dir .. '/lua/async.lua'
      if vim.uv.fs_stat(path) then
        vim.opt.rtp:prepend(dir)
        local ok, mod = pcall(dofile, path)
        if ok then promise_async = mod end
      end
    end

    package.loaded['async'] = nil
    local ok, async_nvim = pcall(dofile, vim.fn.stdpath 'data' .. '/lazy/async.nvim/lua/async.lua')
    if ok and async_nvim then package.loaded['async'] = async_nvim end

    for _, mod in ipairs(async_modules) do
      pcall(require, mod)
    end

    package.loaded['async'] = promise_async or async_nvim

    require('refactoring').setup {
      refactor = {
        extract_func = {
          code_generation = kotlin_code_generation,
        },
      },
    }
  end,
}
