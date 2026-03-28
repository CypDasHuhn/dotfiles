local M = {}
local dep_analyzer = require("dependency-analyzer")

local function is_windows()
	return package.config:sub(1, 1) == "\\"
end

local function quote_cmd_arg(arg)
	return '"' .. tostring(arg):gsub('"', '\\"') .. '"'
end


-- Get the shell directory (where this script lives)
function M.get_shell_dir()
	local info = debug.getinfo(1, "S")
	local path = info.source:match("^@(.*/)")
	return path and path:gsub("/lib/$", "") or "."
end

-- Load and execute a lua file, returning its result
function M.load_file(path)
	local fn, err = loadfile(path)
	if not fn then
		return nil, err
	end
	return fn()
end

-- Get sorted list of files matching pattern in directory
function M.get_sorted_files(dir, pattern)
	local files = {}
	local cmd
	if is_windows() then
		cmd = 'cmd /c dir /b /a-d ' .. quote_cmd_arg(dir:gsub("/", "\\")) .. " 2>nul"
	else
		cmd = 'ls -1 ' .. quote_cmd_arg(dir) .. " 2>/dev/null"
	end

	local handle = io.popen(cmd)
	if not handle then
		return files
	end

	for file in handle:lines() do
		if file:match(pattern) then
			local full = dir .. "/" .. file
			if is_windows() then
				full = full:gsub("\\", "/")
			end
			table.insert(files, full)
		end
	end
	handle:close()

	table.sort(files)
	return files
end

-- Load all var files and merge them in order
function M.load_all_vars(vars_dir)
	local merged = {}
	local order = {}
	local seen = {}
	local files = M.get_sorted_files(vars_dir, "%.lua$")

	for _, file in ipairs(files) do
		local vars = M.load_file(file)
		if vars then
			local file_keys = {}
			for k in pairs(vars) do
				table.insert(file_keys, k)
			end
			table.sort(file_keys)

			for _, k in ipairs(file_keys) do
				merged[k] = vars[k]
				if not seen[k] then
					table.insert(order, k)
					seen[k] = true
				end
			end
		end
	end

	return merged, order
end

local function to_platform(context_type)
	if context_type == "windows" or context_type == "unix" then
		return context_type
	end
	if context_type == "pwsh" then
		return "windows"
	end
	if context_type == "zsh" or context_type == "bash" or context_type == "nushell" then
		return "unix"
	end
	return nil
end

-- Check if a value should be included for this machine/shell/visual.
-- only = { os, shell, visual, machine } — all present keys must match (AND).
function M.should_include(var_def, machine_name, context_type, visual_type)
	if type(var_def) ~= "table" then
		return true
	end

	local only = var_def.only
	if not only then
		return true
	end

	local platform = to_platform(context_type)

	if only.os      and only.os      ~= platform      then return false end
	if only.shell   and only.shell   ~= context_type  then return false end
	if only.visual  and only.visual  ~= visual_type   then return false end
	if only.machine and only.machine ~= machine_name  then return false end

	return true
end

-- Resolve the value for a variable given machine and shell/OS context
function M.resolve_value(var_def, machine_name, context_type)
	if type(var_def) ~= "table" then
		return var_def
	end

	-- Machine-specific override first
	if var_def.machines and var_def.machines[machine_name] then
		return var_def.machines[machine_name]
	end

	-- Shell-specific value
	if var_def[context_type] then
		return var_def[context_type]
	end

	-- Legacy platform fallback (backwards compat + nushell cross-platform fallback)
	local platform = to_platform(context_type)
	if platform and var_def[platform] then
		return var_def[platform]
	end

	return var_def.path or var_def[1]
end

-- Check if variable has dir_function flag
function M.has_dir_function(var_def)
	if type(var_def) ~= "table" then
		return false
	end
	return var_def.dir_function == true
end

-- Convert ${var} syntax to platform-native variable reference
function M.convert_var_refs(value, shell_type)
	if type(value) ~= "string" then
		return value
	end
	return value:gsub("%${([^}]+)}", "$%1")
end

-- Normalize path separators for shell
function M.normalize_path(value, shell_type)
	if type(value) ~= "string" then
		return value
	end
	if shell_type == "pwsh" then
		return value
	else
		return value:gsub("\\", "/")
	end
end

-- Process a value: resolve refs and normalize path
function M.process_value(value, shell_type)
	value = M.convert_var_refs(value, shell_type)
	value = M.normalize_path(value, shell_type)
	return value
end

-- Write content to file
function M.write_file(path, content)
	local dir = path:match("(.+)/[^/]+$") or path:match("(.+)\\[^\\]+$")
	if dir then
		if is_windows() then
			os.execute('cmd /c if not exist ' .. quote_cmd_arg(dir:gsub("/", "\\")) .. " mkdir " .. quote_cmd_arg(dir:gsub("/", "\\")))
		else
			os.execute("mkdir -p " .. quote_cmd_arg(dir))
		end
	end

	local file = io.open(path, "w")
	if not file then
		return false, "Could not open file for writing: " .. path
	end
	file:write(content)
	file:close()
	return true
end

function M.get_ordered_keys(vars)
	local keys = {}
	for k in pairs(vars) do
		table.insert(keys, k)
	end
	table.sort(keys)
	return keys
end

-- Reorder var_order based on dependencies (topological sort)
function M.dependency_sort(vars, var_order, machine_name, shell_type, visual_type)
	local included = {}
	for _, name in ipairs(var_order) do
		local var_def = vars[name]
		if M.should_include(var_def, machine_name, shell_type, visual_type) then
			table.insert(included, name)
		end
	end

	local deps = dep_analyzer.build_graph(vars, function(var_def)
		return M.resolve_value(var_def, machine_name, shell_type)
	end)

	local sorted, err = dep_analyzer.topo_sort(included, deps)
	if not sorted then
		print("Warning: " .. err .. ", falling back to original order")
		return included
	end

	return sorted
end

-- Expand all variable references to their final values
function M.expand_value(value, vars, machine_name, shell_type)
	return dep_analyzer.expand_value(value, vars, function(var_def)
		return M.resolve_value(var_def, machine_name, shell_type)
	end)
end

return M
