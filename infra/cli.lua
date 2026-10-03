local M = {}

function M.print_help()
	print("Usage: lua bootstrap.lua [filter]")
	print("")
	print("Categories:")
	print("  shell    - Shell configuration generation")
	print("  link     - Symlink modules to their destinations")
	print("  deps     - Resolve and install dependencies")
	print("  modules  - Run all module bootstrap scripts")
	print("")
	print("Examples:")
	print("  lua bootstrap.lua             # run everything")
	print("  lua bootstrap.lua shell       # just shell config")
	print("  lua bootstrap.lua deps        # just dependencies")
	print("  lua bootstrap.lua shell,link  # multiple categories")
	print("  lua bootstrap.lua nvim        # specific module only")
end

function M.should_run(filter, category)
	if not filter then return true end
	if filter == category then return true end
	for cat in filter:gmatch("[^,]+") do
		if cat:match("^%s*(.-)%s*$") == category then return true end
	end
	return false
end

function M.is_module_filter(filter, mod)
	if not filter or not mod then return false end
	for cat in filter:gmatch("[^,]+") do
		if cat:match("^%s*(.-)%s*$") == mod then return true end
	end
	return false
end

local CATEGORIES = { shell = true, link = true, modules = true, deps = true }

-- True when the filter is unset or selects at least one module by name, i.e.
-- the filter is not limited to pipeline categories.
function M.has_module_filter(filter)
	if not filter then return true end
	for cat in filter:gmatch("[^,]+") do
		local name = cat:match("^%s*(.-)%s*$")
		if name ~= "" and not CATEGORIES[name] then
			return true
		end
	end
	return false
end

return M
