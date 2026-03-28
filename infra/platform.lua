local M = {}

function M.os_type()
	if os.getenv("WINDIR") or os.getenv("SystemRoot") then
		return "windows"
	end
	if package.config:sub(1, 1) == "\\" then
		return "windows"
	end
	return "unix"
end

return M
