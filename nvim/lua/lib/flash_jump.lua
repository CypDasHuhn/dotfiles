local M = {}

local ALPHA = "abcdefghijklmnopqrstuvwxyz"

--- Jump with flash using an explicit position list.
--- All positions sorted by distance from cursor (nearest first, regardless of direction).
--- Forward positions render with FlashLabel; backward with FlashLabelBackward.
--- @param positions {[1]:integer,[2]:integer}[]  {row,col} pairs, 1-indexed row / 0-indexed col
function M.jump(positions)
  local cur = vim.api.nvim_win_get_cursor(0)
  local cur_row, cur_col = cur[1], cur[2]

  local tagged = {}
  for _, pos in ipairs(positions) do
    local r, c = pos[1], pos[2]
    if r ~= cur_row or c ~= cur_col then
      local is_fwd = r > cur_row or (r == cur_row and c > cur_col)
      -- weight rows heavily so same-line col differences don't dominate
      local dist = math.abs(r - cur_row) * 10000 + math.abs(c - cur_col)
      table.insert(tagged, { pos = pos, fwd = is_fwd, dist = dist })
    end
  end

  table.sort(tagged, function(a, b) return a.dist < b.dist end)

  local matches = {}
  for i, item in ipairs(tagged) do
    local lbl = ALPHA:sub(i, i)
    if lbl == "" then break end
    local pos = item.pos
    table.insert(matches, {
      pos     = { pos[1], pos[2] },
      end_pos = { pos[1], pos[2] },
      label   = lbl,
      _fwd    = item.fwd,
    })
  end

  require("flash").jump({
    matcher = function(_win) return matches end,
    -- no-op: matcher pre-assigns all labels; default labeler would wipe them
    labeler = function() end,
    search = {
      -- max_length=0 bypasses labeler.reset()'s skip-filter (which clears labels on empty pattern)
      max_length  = 0,
      incremental = false,
    },
    jump  = { jumplist = true },
    label = {
      uppercase = false,
      format = function(opts)
        local hl = opts.match._fwd and opts.hl_group or "FlashLabelBackward"
        return { { opts.match.label, hl } }
      end,
    },
    highlight = { matches = false },
  })
end

return M
