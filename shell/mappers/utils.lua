local M = {}
local dep_analyzer = require("dependency-analyzer")

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
	local handle = io.popen('ls -1 "' .. dir .. '" 2>/dev/null')
	if not handle then
		return files
	end

	for file in handle:lines() do
		if file:match(pattern) then
			table.insert(files, dir .. "/" .. file)
		end
	end
	handle:close()

	table.sort(files)
	return files
end

-- Load all var files and merge them in order
-- Returns: vars table, order array (preserves definition order)
function M.load_all_vars(vars_dir)
	local merged = {}
	local order = {}
	local seen = {}
	local files = M.get_sorted_files(vars_dir, "%.lua$")

	for _, file in ipairs(files) do
		local vars = M.load_file(file)
		if vars then
			-- Collect keys from this file and sort them for consistency within a file
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

-- Check if a value should be included for this machine/platform
function M.should_include(var_def, machine_name, os_type)
	if type(var_def) ~= "table" then
		return true
	end

	-- Check platform-only filter (windows/unix)
	if var_def.only then
		-- Normalize to array
		local only = type(var_def.only) == "string" and { var_def.only } or var_def.only

		local dominated_by_platform = false
		local dominated_by_machine = false

		for _, allowed in ipairs(only) do
			if allowed == "windows" or allowed == "unix" then
				dominated_by_platform = true
				if allowed == os_type then
					return true
				end
			else
				dominated_by_machine = true
				if allowed == machine_name then
					return true
				end
			end
		end

		-- If we had platform restrictions and none matched, exclude
		if dominated_by_platform and not dominated_by_machine then
			return false
		end
		-- If we had machine restrictions and none matched, exclude
		if dominated_by_machine then
			return false
		end
	end

	return true
end

-- Resolve the value for a variable given machine and platform
function M.resolve_value(var_def, machine_name, os_type)
	if type(var_def) ~= "table" then
		return var_def
	end

	-- Check for machine-specific override first
	if var_def.machines and var_def.machines[machine_name] then
		return var_def.machines[machine_name]
	end

	-- Check for platform-specific value
	if var_def[os_type] then
		return var_def[os_type]
	end

	-- Fall back to path or implicit [1]
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
function M.convert_var_refs(value, os_type)
	if type(value) ~= "string" then
		return value
	end

	-- Both use $var syntax now (PowerShell session vars, not $env:)
	return value:gsub("%${([^}]+)}", "$%1")
end

-- Normalize path separators for platform
function M.normalize_path(value, os_type)
	if type(value) ~= "string" then
		return value
	end

	if os_type == "windows" then
		-- Keep backslashes for Windows, but convert forward slashes
		-- Actually, PowerShell handles forward slashes fine, so leave as-is
		return value
	else
		-- Convert backslashes to forward slashes for Unix
		return value:gsub("\\", "/")
	end
end

-- Process a value: resolve refs and normalize path
function M.process_value(value, os_type)
	value = M.convert_var_refs(value, os_type)
	value = M.normalize_path(value, os_type)
	return value
end

-- Write content to file
function M.write_file(path, content)
	local file = io.open(path, "w")
	if not file then
		return false, "Could not open file for writing: " .. path
	end
	file:write(content)
	file:close()
	return true
end

-- Get ordered list of variable names (respects definition order roughly)
-- Since Lua tables don't preserve order, we sort alphabetically
-- but the file loading order (00-, 10-, etc.) handles dependencies
function M.get_ordered_keys(vars)
	local keys = {}
	for k in pairs(vars) do
		table.insert(keys, k)
	end
	table.sort(keys)
	return keys
end

-- Reorder var_order based on dependencies (topological sort)
-- Returns: new order with dependencies resolved first
function M.dependency_sort(vars, var_order, machine_name, os_type)
	-- Filter to only included vars
	local included = {}
	for _, name in ipairs(var_order) do
		local var_def = vars[name]
		if M.should_include(var_def, machine_name, os_type) then
			table.insert(included, name)
		end
	end

	-- Build dependency graph using resolved values
	local deps = dep_analyzer.build_graph(vars, function(var_def)
		return M.resolve_value(var_def, machine_name, os_type)
	end)

	-- Topological sort
	local sorted, err = dep_analyzer.topo_sort(included, deps)
	if not sorted then
		print("Warning: " .. err .. ", falling back to original order")
		return included
	end

	return sorted
end

-- Expand all variable references to their final values
function M.expand_value(value, vars, machine_name, os_type)
	return dep_analyzer.expand_value(value, vars, function(var_def)
		return M.resolve_value(var_def, machine_name, os_type)
	end)
end

return M
