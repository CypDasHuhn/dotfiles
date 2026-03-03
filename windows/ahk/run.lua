#!/usr/bin/env lua

local function get_script_dir()
	local source = (arg and arg[0]) or ""
	local path = source:match("(.+[\\/])")
	if path then
		return path:gsub("\\", "/")
	end
	return "./"
end

local function quote_cmd_arg(arg_value)
	return '"' .. tostring(arg_value):gsub('"', '\\"') .. '"'
end

local function to_win_path(path)
	return path:gsub("/", "\\")
end

local function is_abs_path(path)
	if not path or path == "" then
		return false
	end
	return path:match("^%a:[/\\]") or path:match("^\\\\") or path:match("^/") ~= nil
end

local function resolve_path(base, value)
	local candidate = value
	if not is_abs_path(value) then
		candidate = base .. "/" .. value
	end
	local cmd = 'cmd /c for %I in (' .. quote_cmd_arg(to_win_path(candidate)) .. ") do @echo %~fI"
	local handle = io.popen(cmd)
	if handle then
		local result = handle:read("*l")
		handle:close()
		if result and result ~= "" then
			return result
		end
	end
	return candidate
end

local function normalize_path(path)
	return path:gsub("\\", "/"):gsub("/+$", ""):lower()
end

local function is_under_path(path, parent)
	local full = normalize_path(path)
	local root = normalize_path(parent)
	return full == root or full:sub(1, #root + 1) == root .. "/"
end

local function split_path(path)
	local normalized = path:gsub("/", "\\"):gsub("\\+$", "")
	local parts = {}
	for part in normalized:gmatch("[^\\]+") do
		table.insert(parts, part)
	end
	return parts
end

local function get_relative_path(base, target)
	local base_parts = split_path(base)
	local target_parts = split_path(target)
	local i = 1
	while base_parts[i]
		and target_parts[i]
		and base_parts[i]:lower() == target_parts[i]:lower()
	do
		i = i + 1
	end

	local rel = {}
	for j = i, #base_parts do
		table.insert(rel, "..")
	end
	for j = i, #target_parts do
		table.insert(rel, target_parts[j])
	end

	if #rel == 0 then
		return "."
	end
	return table.concat(rel, "\\")
end

local function ensure_dir(path)
	os.execute('cmd /c if not exist ' .. quote_cmd_arg(to_win_path(path)) .. " mkdir " .. quote_cmd_arg(to_win_path(path)))
end

local function ensure_parent_dir(path)
	local dir = path:match("(.+)/[^/]+$") or path:match("(.+)\\[^\\]+$")
	if dir then
		ensure_dir(dir)
	end
end

local function remove_file(path)
	if not path or path == "" then
		return false
	end
	local cmd = "cmd /c del /F /Q " .. quote_cmd_arg(to_win_path(path)) .. " 2>nul"
	local result = os.execute(cmd)
	return result == 0 or result == true
end

local function list_files(dir, pattern)
	local cmd = "cmd /c dir /b /a-d " .. quote_cmd_arg(to_win_path(dir .. "/" .. pattern))
	local handle = io.popen(cmd)
	local files = {}
	if handle then
		for line in handle:lines() do
			if line and line ~= "" then
				table.insert(files, line)
			end
		end
		handle:close()
	end
	table.sort(files, function(a, b)
		return a:lower() < b:lower()
	end)
	return files
end

local function list_files_recursive(dir, pattern)
	local cmd = "cmd /c dir /b /s " .. quote_cmd_arg(to_win_path(dir .. "/" .. pattern))
	local handle = io.popen(cmd)
	local files = {}
	if handle then
		for line in handle:lines() do
			if line and line ~= "" then
				table.insert(files, line)
			end
		end
		handle:close()
	end
	table.sort(files, function(a, b)
		return a:lower() < b:lower()
	end)
	return files
end

local function read_file(path)
	local file = io.open(path, "rb")
	if not file then
		return nil
	end
	local content = file:read("*a")
	file:close()
	return content
end

local function write_file(path, content)
	ensure_parent_dir(path)
	local file = io.open(path, "wb")
	if not file then
		return false, "Could not open file for writing: " .. path
	end
	file:write(content)
	file:close()
	return true
end

local function copy_file(src, dst)
	local content = read_file(src)
	if not content then
		return false, "Failed to read: " .. src
	end
	local ok, err = write_file(dst, content)
	if not ok then
		return false, err
	end
	return true
end

local function load_file(path)
	local fn, err = loadfile(path)
	if not fn then
		return nil, err
	end
	return fn()
end

local function parse_args(argv)
	local out = {}
	local i = 1
	while i <= #argv do
		local key = argv[i]
		if key:sub(1, 1) == "-" then
			local name = key:gsub("^%-%-?", ""):lower()
			local value = argv[i + 1]
			if value and value:sub(1, 1) ~= "-" then
				out[name] = value
				i = i + 1
			else
				out[name] = true
			end
		end
		i = i + 1
	end
	return out
end

local script_dir = get_script_dir()
local root = resolve_path(".", script_dir)

local args = parse_args(arg or {})
local source_dir = resolve_path(root, args.sourcedir or ".")
local generated_dir = resolve_path(root, args.generateddir or "./generated")
local mappers_dir = resolve_path(root, args.mappersdir or "./mappers")
local generators_dir = resolve_path(root, args.generatorsdir or "./generators")

local dotfiles_dir = resolve_path(root, "../..")
local machine_file = resolve_path(dotfiles_dir, args.machinefile or ".machine.local.lua")

local machine = load_file(machine_file)
if not machine then
	print("Error: Could not load machine config from " .. machine_file)
	os.exit(1)
end

local machine_name = machine.name or os.getenv("COMPUTERNAME") or ""
if machine_name == "" then
	print("Error: Machine name is required")
	os.exit(1)
end

ensure_dir(generated_dir)

local source_files = list_files_recursive(source_dir, "*.ahk")
local expected = {}
for _, file in ipairs(source_files) do
	if not is_under_path(file, generated_dir)
		and not is_under_path(file, mappers_dir)
		and not is_under_path(file, generators_dir)
	then
		local relative = get_relative_path(source_dir, file)
		expected[relative:lower()] = true
		local output_path = generated_dir .. "\\" .. relative
		local ok, err = copy_file(file, output_path)
		if not ok then
			print("Error: " .. err)
			os.exit(1)
		end
	end
end

local generated_files = list_files_recursive(generated_dir, "*.ahk")
for _, file in ipairs(generated_files) do
	local relative = get_relative_path(generated_dir, file)
	if relative ~= "." and not expected[relative:lower()] then
		remove_file(file)
	end
end

local helpers = {
	list_files = list_files,
	list_files_recursive = list_files_recursive,
	read_file = read_file,
	write_file = write_file,
	get_relative_path = get_relative_path,
}

local context = {
	source_dir = source_dir,
	generated_dir = generated_dir,
	mappers_dir = mappers_dir,
	generators_dir = generators_dir,
	machine_name = machine_name,
	helpers = helpers,
}

local mapper_files = list_files(mappers_dir, "*.lua")
for _, file in ipairs(mapper_files) do
	local path = mappers_dir .. "\\" .. file
	local fn, err = loadfile(path)
	if not fn then
		print("Error: Failed to load mapper " .. file .. ": " .. (err or "unknown"))
		os.exit(1)
	end
	local ok, mod = pcall(fn)
	if not ok then
		print("Error: Failed to run mapper " .. file .. ": " .. (mod or "unknown"))
		os.exit(1)
	end
	if type(mod) == "function" then
		mod(context)
	elseif type(mod) == "table" and type(mod.run) == "function" then
		mod.run(context)
	else
		print("Error: Mapper " .. file .. " must return a function or { run = function }")
		os.exit(1)
	end
end

local generator_files = list_files(generators_dir, "*.lua")
local home_files = {}
local other_files = {}
for _, file in ipairs(generator_files) do
	if file:lower() == "home.lua" then
		table.insert(home_files, file)
	else
		table.insert(other_files, file)
	end
end

local function run_generators(files)
	for _, file in ipairs(files) do
		local path = generators_dir .. "\\" .. file
		local fn, err = loadfile(path)
		if not fn then
			print("Error: Failed to load generator " .. file .. ": " .. (err or "unknown"))
			os.exit(1)
		end
		local ok, mod = pcall(fn)
		if not ok then
			print("Error: Failed to run generator " .. file .. ": " .. (mod or "unknown"))
			os.exit(1)
		end
		if type(mod) == "function" then
			mod(context)
		elseif type(mod) == "table" and type(mod.run) == "function" then
			mod.run(context)
		else
			print("Error: Generator " .. file .. " must return a function or { run = function }")
			os.exit(1)
		end
	end
end

run_generators(other_files)
run_generators(home_files)

print("AHK generation complete.")
print("Source:    " .. source_dir)
print("Generated: " .. generated_dir)
print("Machine:   " .. machine_name)
