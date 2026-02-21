local M = {}

-- Extract all ${var} references from a string
function M.extract_refs(value)
	local refs = {}
	if type(value) ~= "string" then
		return refs
	end
	for ref in value:gmatch("%${([^}]+)}") do
		table.insert(refs, ref)
	end
	return refs
end

-- Build dependency graph from vars table
-- Returns: deps[name] = {list of vars this name depends on}
function M.build_graph(vars, resolve_value_fn)
	local deps = {}
	for name, var_def in pairs(vars) do
		local value = resolve_value_fn(var_def)
		deps[name] = M.extract_refs(value)
	end
	return deps
end

-- Topological sort using Kahn's algorithm
-- Returns: sorted list of names, or nil + error if cycle detected
function M.topo_sort(names, deps)
	-- Build in-degree count and adjacency list
	local in_degree = {}
	local dependents = {} -- dependents[a] = list of names that depend on a

	for _, name in ipairs(names) do
		in_degree[name] = 0
		dependents[name] = {}
	end

	-- Count incoming edges
	for _, name in ipairs(names) do
		local name_deps = deps[name] or {}
		for _, dep in ipairs(name_deps) do
			if in_degree[dep] ~= nil then -- only count deps that exist in our set
				in_degree[name] = in_degree[name] + 1
				table.insert(dependents[dep], name)
			end
		end
	end

	-- Start with nodes that have no dependencies
	local queue = {}
	for _, name in ipairs(names) do
		if in_degree[name] == 0 then
			table.insert(queue, name)
		end
	end

	local sorted = {}
	while #queue > 0 do
		-- Sort queue for deterministic output
		table.sort(queue)
		local name = table.remove(queue, 1)
		table.insert(sorted, name)

		for _, dependent in ipairs(dependents[name]) do
			in_degree[dependent] = in_degree[dependent] - 1
			if in_degree[dependent] == 0 then
				table.insert(queue, dependent)
			end
		end
	end

	if #sorted ~= #names then
		-- Find cycle for error message
		local remaining = {}
		for _, name in ipairs(names) do
			if in_degree[name] > 0 then
				table.insert(remaining, name)
			end
		end
		return nil, "Circular dependency detected involving: " .. table.concat(remaining, ", ")
	end

	return sorted
end

-- Expand all variable references in a value to their final form
-- vars: the vars table
-- resolve_fn: function to resolve a var_def to its raw value
-- Returns fully expanded string
function M.expand_value(value, vars, resolve_fn)
	if type(value) ~= "string" then
		return value
	end

	local max_iterations = 100 -- prevent infinite loops
	local iterations = 0

	while iterations < max_iterations do
		local new_value = value:gsub("%${([^}]+)}", function(ref)
			local var_def = vars[ref]
			if var_def then
				return resolve_fn(var_def)
			end
			return "${" .. ref .. "}" -- keep unresolved
		end)

		if new_value == value then
			break
		end
		value = new_value
		iterations = iterations + 1
	end

	-- Also expand $var syntax (without braces) for already-processed refs
	iterations = 0
	while iterations < max_iterations do
		local new_value = value:gsub("%$([%w_]+)", function(ref)
			local var_def = vars[ref]
			if var_def then
				return resolve_fn(var_def)
			end
			return "$" .. ref -- keep unresolved
		end)

		if new_value == value then
			break
		end
		value = new_value
		iterations = iterations + 1
	end

	return value
end

return M
