-- Platform-aware filesystem operations
-- Usage: local fs = require("fs").new(os_type)

local function quote_cmd_arg(arg)
	return '"' .. tostring(arg):gsub('"', '\\"') .. '"'
end

local function new(os_type)
	local M = {}

	function M.exists(path)
		if not path or path == "" then
			return false
		end

		if os_type == "windows" then
			local handle = io.popen("cmd /c if exist " .. quote_cmd_arg(path:gsub("/", "\\")) .. " (echo yes) else (echo no)")
			if handle then
				local result = handle:read("*l")
				handle:close()
				return result == "yes"
			end
			return false
		end

		local handle = io.popen("test -e " .. quote_cmd_arg(path) .. " && echo yes || echo no")
		if handle then
			local result = handle:read("*l")
			handle:close()
			return result == "yes"
		end
		return false
	end

	function M.is_symlink(path)
		if os_type == "unix" then
			local handle = io.popen('test -L "' .. path .. '" && echo yes || echo no')
			if handle then
				local result = handle:read("*l")
				handle:close()
				return result == "yes"
			end
		else
			local win_path = path:gsub("/", "\\")
			local handle = io.popen(
				"cmd /c if exist "
					.. quote_cmd_arg(win_path)
					.. " (fsutil reparsepoint query "
					.. quote_cmd_arg(win_path)
					.. " >nul 2>&1 && echo yes || echo no) else echo no"
			)
			if handle then
				local result = handle:read("*l")
				handle:close()
				return result == "yes"
			end
		end
		return false
	end

	function M.readlink(path)
		if os_type == "unix" then
			local handle = io.popen('readlink "' .. path .. '"')
			if handle then
				local target = handle:read("*l")
				handle:close()
				return target
			end
		else
			local win_path = path:gsub("/", "\\")
			local ps_path = win_path:gsub("'", "''")
			local cmd = 'powershell -NoProfile -Command "$item = Get-Item -LiteralPath \'' .. ps_path
				.. '\'; if ($item -and $item.Target) { @($item.Target)[0] }"'
			local handle = io.popen(cmd)
			if handle then
				local target = handle:read("*l")
				handle:close()
				if target and target ~= "" then
					return target
				end
			end
		end
		return nil
	end

	function M.mkdir_p(path)
		local dir = path:match("(.+)/[^/]+$") or path:match("(.+)\\[^\\]+$")
		if not dir then
			return true
		end
		if os_type == "unix" then
			os.execute('mkdir -p "' .. dir .. '"')
		else
			os.execute('mkdir "' .. dir:gsub("/", "\\") .. '" 2>nul')
		end
		return true
	end

	function M.is_directory(path)
		if os_type == "unix" then
			local handle = io.popen("test -d " .. quote_cmd_arg(path) .. " && echo yes || echo no")
			if handle then
				local result = handle:read("*l")
				handle:close()
				return result == "yes"
			end
			return false
		end
		-- "\*" reliably detects directory containers across Windows setups
		local win_path = path:gsub("/", "\\")
		local handle = io.popen("cmd /c if exist " .. quote_cmd_arg(win_path .. "\\*") .. " (echo yes) else (echo no)")
		if handle then
			local result = handle:read("*l")
			handle:close()
			return result == "yes"
		end
		return false
	end

	function M.remove_path(path)
		if os_type == "unix" then
			local result = os.execute("rm -rf " .. quote_cmd_arg(path))
			if result ~= 0 and result ~= true then
				return false, "Failed to remove target: " .. path
			end
		else
			local win_path = path:gsub("/", "\\")
			local cmd = "cmd /c (rmdir " .. quote_cmd_arg(win_path) .. " >nul 2>&1)"
				.. " & (rmdir /S /Q " .. quote_cmd_arg(win_path) .. " >nul 2>&1)"
				.. " & (del /F /Q " .. quote_cmd_arg(win_path) .. " >nul 2>&1)"
			local result = os.execute(cmd)
			if result ~= 0 and result ~= true then
				return false, "Failed to remove target: " .. path
			end
		end

		if M.exists(path) or M.is_symlink(path) then
			return false, "Target still exists after removal attempt: " .. path
		end
		return true
	end

	return M
end

return { new = new }
