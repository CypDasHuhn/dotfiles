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

-- Step 3: Run each module's bootstrap
local modules = {
	"nvim",
	-- Add more modules here as needed
}

for _, mod in ipairs(modules) do
	local bootstrap_path = script_dir .. mod .. "/bootstrap.lua"
	local f = io.open(bootstrap_path, "r")
	if f then
		local content = f:read("*a")
		f:close()
		-- Only run if bootstrap has content
		if content and content:match("%S") then
			print("Running " .. mod .. " bootstrap...")
			dofile(bootstrap_path)
		end
	end
end

print("")
print("=== Bootstrap Complete ===")
