local M = {}

local comment_starters = { '//', '#', '--', '*', '<!--', '/*', ';', '%' }
local region_start = 'region'
local region_end = 'endregion'

local function line_matches_keyword(line, keyword, starters)
  for _, starter in ipairs(starters) do
    if line:match('^%s*' .. vim.pesc(starter) .. '%s*' .. keyword .. '%f[%W]') then
      return true
    end
  end
  return false
end

function M.get_region_ranges(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local ranges = {}
  local starts = {}
  local stack = {}

  for i, line in ipairs(lines) do
    if line_matches_keyword(line, region_start, comment_starters) then
      table.insert(stack, i)
    elseif line_matches_keyword(line, region_end, comment_starters) then
      if #stack > 0 then
        local start_line = table.remove(stack)
        table.insert(starts, start_line)
        table.insert(ranges, {
          startLine = start_line - 1,
          endLine = i - 1,
          kind = 'region',
        })
      end
    end
  end

  return ranges, starts
end

return M
