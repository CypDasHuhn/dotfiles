#!/usr/bin/env lua

-- Dotfiles Bootstrap
-- Orchestrates shell generation and module linking

local script_dir = arg[0]:match("(.*/)")
if not script_dir then
	script_dir = "./"
end

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

	print("=== Machine Setup ===")
	print("")
	print("No .machine.local.lua found. Let's create one.")
	print("")

	-- Auto-detect OS
	local os_type = detect_os_type()
	print("Detected OS: " .. os_type)

	-- Ask for machine name
	local name = prompt("Enter a name for this machine: ")
	if not name or name == "" then
		print("Error: Machine name is required")
		os.exit(1)
	end

	-- Write the config file
	local config = string.format([[return {
	name = "%s",
	os = {
		type = "%s",
	},
}
]], name, os_type)

	local out = io.open(machine_path, "w")
	if not out then
		print("Error: Could not write to " .. machine_path)
		os.exit(1)
	end
	out:write(config)
	out:close()

	print("")
	print("Created: " .. machine_path)
	print("")

	return true
end

print("=== Dotfiles Bootstrap ===")
print("")

-- Step 0: Ensure machine config exists
ensure_machine_config()

-- Step 1: Run shell generator
print("--- Shell Configuration ---")
local shell_run = script_dir .. "shell/run.lua"
local shell_result = os.execute('lua "' .. shell_run .. '"')
if shell_result ~= 0 and shell_result ~= true then
	print("Error: Shell generation failed")
	os.exit(1)
end
print("")

-- Step 2: Initialize linker
print("--- Linking Modules ---")
package.path = script_dir .. "linking/?.lua;" .. package.path
local linker = require("linker")
linker.init()
print("")

-- Step 3: Discover and run module bootstraps
local function find_bootstraps()
	local bootstraps = {}
	local os_type = detect_os_type()

	-- List directories and find bootstrap.lua files
	local cmd
	if os_type == "unix" then
		cmd = 'find "' .. script_dir .. '" -maxdepth 2 -name "bootstrap.lua" -type f 2>/dev/null'
	else
		cmd = 'dir /s /b "' .. script_dir:gsub("/", "\\") .. 'bootstrap.lua" 2>nul'
	end

	local handle = io.popen(cmd)
	if handle then
		for line in handle:lines() do
			-- Skip the root bootstrap.lua
			if not line:match("dotfiles/bootstrap.lua$") and not line:match("dotfiles\\bootstrap.lua$") then
				table.insert(bootstraps, line)
			end
		end
		handle:close()
	end

	table.sort(bootstraps)
	return bootstraps
end

for _, bootstrap_path in ipairs(find_bootstraps()) do
	-- Extract module name from path
	local mod = bootstrap_path:match("/([^/]+)/bootstrap%.lua$") or bootstrap_path:match("\\([^\\]+)\\bootstrap%.lua$")
	if mod then
		print("Running " .. mod .. " bootstrap...")
		dofile(bootstrap_path)
	end
end

print("")
print("=== Bootstrap Complete ===")
