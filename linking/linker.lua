-- Linker module - OS-agnostic symlink management for dotfiles
-- Uses .machine.local.lua and shell/vars to resolve paths

local M = {}

-- Get the linker directory (where this script lives)
local function get_linker_dir()
	local info = debug.getinfo(1, "S")
	local path = info.source:match("^@(.*/)")
	return path or "./"
end

local linker_dir = get_linker_dir()
local dotfiles_dir = linker_dir .. "../"

-- Add shell mappers to package path for utils
package.path = dotfiles_dir .. "shell/mappers/?.lua;" .. package.path

local utils = require("utils")

-- State
local machine = nil
local vars = nil
local var_order = nil

-- Initialize the linker with machine config
function M.init()
	local machine_path = dotfiles_dir .. ".machine.local.lua"
	machine = utils.load_file(machine_path)
	if not machine then
		error("Could not load machine config from: " .. machine_path)
	end

	-- Load vars from shell
	local vars_dir = dotfiles_dir .. "shell/vars"
	vars, var_order = utils.load_all_vars(vars_dir)

	print("[linker] Machine: " .. machine.name)
	print("[linker] OS: " .. machine.os.type)

	return M
end

-- Get current machine info
function M.machine()
	return machine
end

-- Expand environment variables in a path
function M.expand_env(path)
	if not path then
		return nil
	end

	if machine.os.type == "unix" then
		-- Expand $HOME and $VAR
		path = path:gsub("%$HOME", os.getenv("HOME") or "")
		path = path:gsub("%$([%w_]+)", function(var)
			return os.getenv(var) or ("$" .. var)
		end)
	else
		-- Windows: expand %USERPROFILE% etc.
		path = path:gsub("%%([^%%]+)%%", function(var)
			return os.getenv(var) or ("%" .. var .. "%")
		end)
		-- Also handle $HOME style for consistency
		path = path:gsub("%$HOME", os.getenv("USERPROFILE") or "")
	end

	return path
end

-- Resolve a variable name to its full expanded path
function M.resolve(var_name)
	local var_def = vars[var_name]
	if not var_def then
		return nil, "Variable not found: " .. var_name
	end

	if not utils.should_include(var_def, machine.name, machine.os.type) then
		return nil, "Variable excluded for this machine/OS: " .. var_name
	end

	local value = utils.resolve_value(var_def, machine.name, machine.os.type)
	if not value then
		return nil, "Could not resolve value for: " .. var_name
	end

	-- Expand variable references ${var}
	value = utils.expand_value(value, vars, machine.name, machine.os.type)

	-- Process for platform (normalize paths)
	value = utils.process_value(value, machine.os.type)

	-- Expand environment variables
	value = M.expand_env(value)

	return value
end

-- Check if a path exists
function M.exists(path)
	local f = io.open(path, "r")
	if f then
		f:close()
		return true
	end
	return false
end

-- Check if a path is a symlink
function M.is_symlink(path)
	if machine.os.type == "unix" then
		local handle = io.popen('test -L "' .. path .. '" && echo yes || echo no')
		if handle then
			local result = handle:read("*l")
			handle:close()
			return result == "yes"
		end
	else
		-- Windows: check for reparse point
		local handle = io.popen('cmd /c "if exist "' .. path .. '" (fsutil reparsepoint query "' .. path .. '" >nul 2>&1 && echo yes || echo no) else echo no"')
		if handle then
			local result = handle:read("*l")
			handle:close()
			return result == "yes"
		end
	end
	return false
end

-- Get the target of a symlink
function M.readlink(path)
	if machine.os.type == "unix" then
		local handle = io.popen('readlink "' .. path .. '"')
		if handle then
			local target = handle:read("*l")
			handle:close()
			return target
		end
	end
	return nil
end

-- Create parent directories if they don't exist
function M.mkdir_p(path)
	local dir = path:match("(.+)/[^/]+$") or path:match("(.+)\\[^\\]+$")
	if not dir then
		return true
	end

	if machine.os.type == "unix" then
		os.execute('mkdir -p "' .. dir .. '"')
	else
		os.execute('mkdir "' .. dir:gsub("/", "\\") .. '" 2>nul')
	end
	return true
end

-- Create a symlink from source to target
-- source: the actual files (in dotfiles)
-- target: where the symlink should be created (system location)
function M.link(source, target)
	if not source or not target then
		return false, "Source and target are required"
	end

	-- Check source exists
	if not M.exists(source) then
		return false, "Source does not exist: " .. source
	end

	-- Check if target already exists
	if M.exists(target) or M.is_symlink(target) then
		if M.is_symlink(target) then
			local current = M.readlink(target)
			if current == source then
				print("[linker] Already linked: " .. target .. " -> " .. source)
				return true, "already linked"
			else
				print("[linker] Warning: " .. target .. " points to " .. (current or "unknown"))
				return false, "Symlink exists but points elsewhere: " .. (current or "unknown")
			end
		else
			return false, "Target exists and is not a symlink: " .. target
		end
	end

	-- Create parent directories
	M.mkdir_p(target)

	-- Create the symlink
	local cmd
	if machine.os.type == "unix" then
		cmd = string.format('ln -s "%s" "%s"', source, target)
	else
		-- Windows: use mklink (needs admin or dev mode)
		-- /D for directory, /H for hard link (files only)
		local is_dir = M.exists(source .. "/") or M.exists(source .. "\\")
		if is_dir then
			cmd = string.format('mklink /D "%s" "%s"', target:gsub("/", "\\"), source:gsub("/", "\\"))
		else
			cmd = string.format('mklink "%s" "%s"', target:gsub("/", "\\"), source:gsub("/", "\\"))
		end
	end

	local result = os.execute(cmd)
	if result == 0 or result == true then
		print("[linker] Linked: " .. target .. " -> " .. source)
		return true
	else
		return false, "Failed to create symlink"
	end
end

-- Link using variable names from shell/vars
-- source_var: variable name for source (e.g., "nvim")
-- target_var: variable name for target (e.g., "systemNvim")
function M.link_var(source_var, target_var)
	local source, err1 = M.resolve(source_var)
	if not source then
		return false, "Could not resolve source var '" .. source_var .. "': " .. (err1 or "unknown")
	end

	local target, err2 = M.resolve(target_var)
	if not target then
		return false, "Could not resolve target var '" .. target_var .. "': " .. (err2 or "unknown")
	end

	return M.link(source, target)
end

-- Convenience function for bootstrap files:
-- Links the current module directory to its system location
-- module_name: name used in vars (e.g., "nvim")
-- Expects vars to define: {module_name} and system{ModuleName}
function M.link_module(module_name)
	local system_var = "system" .. module_name:sub(1, 1):upper() .. module_name:sub(2)
	return M.link_var(module_name, system_var)
end

return M
