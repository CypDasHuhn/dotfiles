local platform = require("platform")

local M = {}

local function find_dir_lua(bootstrap_path, root)
	local dir = bootstrap_path:gsub("\\", "/"):match("(.+)/[^/]+$")
	while dir and #dir >= #root do
		local f = io.open(dir .. "/dir.lua", "r")
		if f then
			f:close()
			return dir .. "/dir.lua"
		end
		dir = dir:match("(.+)/[^/]+$")
	end
	return nil
end

local function should_run(path, machine, root)
	local dir_lua_path = find_dir_lua(path, root)
	if not dir_lua_path then return true end
	local chunk = loadfile(dir_lua_path)
	if not chunk then return true end
	local ok, meta = pcall(chunk)
	if not ok or type(meta) ~= "table" then return true end
	local only = meta.only
	if not only then return true end
	local os_type = machine.os and machine.os.type
	local visual_type = machine.os and machine.os.visual
	if only.os      and only.os      ~= os_type      then return false end
	if only.visual  and only.visual  ~= visual_type  then return false end
	if only.machine and only.machine ~= machine.name then return false end
	return true
end

function M.find(script_dir, machine)
	local bootstraps = {}
	local root = script_dir:gsub("/$", "")

	local cmd
	if platform.os_type() == "unix" then
		cmd = 'find "' .. script_dir .. '" -name "bootstrap.lua" -type f 2>/dev/null'
	else
		-- dir /s /b follows symlinks/junctions and can cause infinite loops.
		-- Use a PowerShell recursive search that skips reparse point directories.
		local win_root = script_dir:gsub("/", "\\")
		local ps_root = win_root:gsub("'", "''")
		cmd = 'powershell -NoProfile -Command "& { function S($d){ Get-ChildItem $d -File -Filter bootstrap.lua -EA 0 | ForEach-Object { $_.FullName }; Get-ChildItem $d -Directory -EA 0 | Where-Object { !($_.Attributes -band 1024) } | ForEach-Object { S $_.FullName } }; S \'' .. ps_root .. '\'}"'
	end

	local handle = io.popen(cmd)
	if handle then
		for line in handle:lines() do
			if
				not line:match("dotfiles/bootstrap%.lua$")
				and not line:match("dotfiles\\bootstrap%.lua$")
				and should_run(line, machine, root)
			then
				table.insert(bootstraps, line)
			end
		end
		handle:close()
	end

	table.sort(bootstraps)
	return bootstraps
end

return M
