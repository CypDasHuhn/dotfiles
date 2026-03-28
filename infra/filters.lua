-- Filter helpers for the `only` property.
-- Each function returns a plain table; keys present in the table are ANDed together.
-- You can also write the table directly: only = { os = "unix", machine = "work-laptop" }
local M = {}

function M.os(value)
	return { os = value }
end

function M.shell(value)
	return { shell = value }
end

function M.visual(value)
	return { visual = value }
end

function M.machine(name)
	return { machine = name }
end

return M
