# Ufo fold

```lua
local function get_region_ranges(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local ranges = {}
  local stack = {}

  for lnum, line in ipairs(lines) do
    -- match "region" as a keyword (preceded by non-alpha: comment chars, whitespace, SOL)
    if line:match('%f[%a]region%f[%A]') then
      table.insert(stack, { startLine = lnum - 1, name = line:match('region%s+(.-)%s*$') })
    elseif line:match('%f[%a]endregion%f[%A]') then
      if #stack > 0 then
        local top = table.remove(stack)
        table.insert(ranges, {
          startLine = top.startLine,
          endLine = lnum - 1,
          kind = vim.lsp.protocol.FoldingRangeKind.Region,
        })
      end
    end
  end

  return ranges
end

require('ufo').setup({
  provider_selector = function(bufnr, filetype, buftype)
    return function(bufnr)
      return require('ufo.provider.treesitter').getFolds(bufnr)
        :thenCall(function(ts_ranges)
          local region_ranges = get_region_ranges(bufnr)
          return vim.list_extend(ts_ranges, region_ranges)
        end)
        :catch(function()
          -- treesitter not available for this buffer, fall back to regions only
          return get_region_ranges(bufnr)
        end)
    end
  end,
})
```
