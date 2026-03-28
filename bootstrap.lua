#!/usr/bin/env lua

-- Dotfiles Bootstrap
-- Orchestrates shell generation and module linking

local function get_script_dir()
	local source = (arg and arg[0]) or ""
	local path = source:match("(.+[\\/])")
	if path then
		return path:gsub("\\", "/")
	end
	return "./"
end
local script_dir = get_script_dir()

package.path = script_dir .. "infra/?.lua;" .. package.path
local c = require("colors")

-- Detect OS type
local function detect_os_type()
	-- Check for Windows-specific env vars
	if os.getenv("WINDIR") or os.getenv("SystemRoot") then
		return "windows"
	end
	-- Check using package.config (first char is dir separator)
	if package.config:sub(1, 1) == "\\" then
		return "windows"
	end
	return "unix"
end

-- Prompt user for input
local function prompt(message)
	io.write(message)
	io.flush()
	local input = io.read("*l")
	return input and input:match("^%s*(.-)%s*$") -- trim whitespace
end

-- Check if .machine.local.lua exists, create if not
local function ensure_machine_config()
	local machine_path = script_dir .. ".machine.local.lua"
	local f = io.open(machine_path, "r")
	if f then
		f:close()
		return true
	end

	c.header("Machine Setup")
	print("")
	c.info("No .machine.local.lua found. Let's create one.")
	print("")

	-- Auto-detect OS
	local os_type = detect_os_type()
	c.info("Detected OS: " .. os_type)

	-- Ask for machine name
	local name = prompt("Enter a name for this machine: ")
	if not name or name == "" then
		c.err("Machine name is required")
		os.exit(1)
	end

	-- Write the config file
	local config = string.format(
		[[return {
	name = "%s",
	os = {
		type = "%s",
	},
}
]],
		name,
		os_type
	)

	local out = io.open(machine_path, "w")
	if not out then
		c.err("Could not write to " .. machine_path)
		os.exit(1)
	end
	out:write(config)
	out:close()

	print("")
	c.ok("Created: " .. machine_path)
	print("")

	return true
end

-- Parse filter argument
local filter = arg and arg[1]

-- Show help
if filter == "--help" or filter == "-h" then
	print("Usage: lua bootstrap.lua [filter]")
	print("")
	print("Categories:")
	print("  shell    - Shell configuration generation")
	print("  link     - Symlink modules to their destinations")
	print("  modules  - Run all module bootstrap scripts")
	print("  deps     - Resolve and install dependencies")
	print("")
	print("Examples:")
	print("  lua bootstrap.lua          # run everything")
	print("  lua bootstrap.lua shell    # just shell config")
	print("  lua bootstrap.lua deps     # just dependencies")
	print("  lua bootstrap.lua shell,link  # multiple categories")
	print("  lua bootstrap.lua nvim     # specific module only")
	os.exit(0)
end

c.header("Dotfiles Bootstrap")
print("")
local function should_run(category)
	if not filter then return true end
	-- Check if category matches or is in comma-separated list
	if filter == category then return true end
	for cat in filter:gmatch("[^,]+") do
		if cat:match("^%s*(.-)%s*$") == category then return true end
	end
	return false
end

-- Step 0: Ensure machine config exists
ensure_machine_config()

-- Step 1: Run shell generator
if should_run("shell") then
	c.section("Shell Configuration")
	local shell_run = script_dir .. "shell/run.lua"
	local shell_result = os.execute('lua "' .. shell_run .. '"')
	if shell_result ~= 0 and shell_result ~= true then
		c.err("Shell generation failed")
		os.exit(1)
	end
	print("")
end

-- Step 2: Initialize linker (always needed for machine detection)
package.path = script_dir .. "infra/?.lua;" .. script_dir .. "terminal/emulator/?.lua;" .. package.path
local ok, linker = pcall(require, "linker")
if not ok or not linker then
	c.err("Failed to load linker: " .. tostring(linker))
	os.exit(1)
end
linker.init()

if should_run("link") then
	c.section("Linking Modules")
	-- linker.init() already ran, actual linking happens in module bootstraps
	print("")
end

-- Step 3: Discover and run module bootstraps

-- Walk up from a bootstrap file's directory to find the nearest dir.lua
local function find_dir_lua(bootstrap_path)
	local root = script_dir:gsub("/$", "")
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

local function should_run_bootstrap(path, machine)
	local dir_lua_path = find_dir_lua(path)
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

local function find_bootstraps(machine)
	local bootstraps = {}
	local os_type = detect_os_type()

	local cmd
	if os_type == "unix" then
		cmd = 'find "' .. script_dir .. '" -name "bootstrap.lua" -type f 2>/dev/null'
	else
		cmd = 'dir /s /b "' .. script_dir:gsub("/", "\\") .. 'bootstrap.lua" 2>nul'
	end

	local handle = io.popen(cmd)
	if handle then
		for line in handle:lines() do
			if
				not line:match("dotfiles/bootstrap.lua$")
				and not line:match("dotfiles\\bootstrap.lua$")
				and should_run_bootstrap(line, machine)
			then
				table.insert(bootstraps, line)
			end
		end
		handle:close()
	end

	table.sort(bootstraps)
	return bootstraps
end

-- Check if filter is a specific module name
local function is_module_filter(mod)
	if not filter then return false end
	for cat in filter:gmatch("[^,]+") do
		local trimmed = cat:match("^%s*(.-)%s*$")
		if trimmed == mod then return true end
	end
	return false
end

if should_run("modules") or is_module_filter(filter) then
	c.section("Module Bootstraps")
	for _, bootstrap_path in ipairs(find_bootstraps(linker.machine())) do
		local mod = bootstrap_path:match("/([^/]+)/bootstrap%.lua$") or bootstrap_path:match("\\([^\\]+)\\bootstrap%.lua$")
		if mod and (should_run("modules") or is_module_filter(mod)) then
			c.tag(mod, "running bootstrap...")
			dofile(bootstrap_path)
		end
	end
	print("")
end

-- Step 4: Resolve dependencies
if should_run("deps") then
	c.section("Dependencies")
	local deps = require("dependencies.init")
	deps.run(script_dir)
	print("")
end

c.header("Bootstrap Complete")
