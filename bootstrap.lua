#!/usr/bin/env lua

-- Dotfiles Bootstrap
-- Orchestrates shell generation and module linking

local script_dir = arg[0]:match("(.*/)")
if not script_dir then
	script_dir = "./"
end

print("=== Dotfiles Bootstrap ===")
print("")

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
