-- Linker module - OS-agnostic symlink management for dotfiles
-- Uses .machine.local.lua and shell/vars to resolve paths

local M = {}

local function get_linker_dir()
	local info = debug.getinfo(1, "S")
	local source = info and info.source or ""
	local path = source:match("^@(.+[\\/])")
	if path then
		return path:gsub("\\", "/")
	end
	return "./"
end

local linker_dir = get_linker_dir()
local dotfiles_dir = linker_dir .. "../"

package.path = dotfiles_dir .. "shell/mappers/?.lua;" .. linker_dir .. "?.lua;" .. package.path

local utils = require("utils")
local fs_mod = require("fs")
local resolver_mod = require("resolver")
local c = require("colors")

-- State
local machine = nil
local fs = nil
local resolver = nil

local function normalize_path(path, os_type)
	if not path then
		return nil
	end
	local normalized = path
	if os_type == "windows" then
		normalized = normalized:gsub("\\", "/"):gsub("/+$", ""):lower()
	else
		normalized = normalized:gsub("/+$", "")
	end
	return normalized
end

-- Read the TargetPath of a Windows .lnk shortcut (nil if not a shortcut).
local function read_shortcut_target(path)
	local ps_path = path:gsub("/", "\\"):gsub("'", "''")
	local cmd = "powershell -NoProfile -Command \"$s = (New-Object -ComObject WScript.Shell).CreateShortcut('"
		.. ps_path
		.. "'); if ($s) { $s.TargetPath }\" 2>nul"
	local handle = io.popen(cmd)
	if not handle then
		return nil
	end
	local target = handle:read("*l")
	handle:close()
	if target and target ~= "" then
		return target
	end
	return nil
end

function M.init()
	local machine_path = dotfiles_dir .. ".machine.local.lua"
	machine = utils.load_file(machine_path)
	if not machine then
		error("Could not load machine config from: " .. machine_path)
	end

	local vars_dir = dotfiles_dir .. "shell/vars"
	local vars = utils.load_all_vars(vars_dir)

	fs = fs_mod.new(machine.os.type)
	resolver = resolver_mod.new(vars, machine, utils)

	c.tag("linker", "machine: " .. machine.name)
	c.tag("linker", "os: " .. machine.os.type)
	if machine.os.visual then
		c.tag("linker", "visual: " .. machine.os.visual)
	end

	return M
end

function M.machine()
	return machine
end

-- Resolve a variable name to its expanded path
function M.resolve(var_name)
	if not machine then M.init() end
	return resolver.resolve(var_name)
end

-- Create a symlink: source = dotfiles path, target = system location
function M.link(source, target)
	if not source or not target then
		return false, "Source and target are required"
	end

	if not fs.exists(source) then
		return false, "Source does not exist: " .. source
	end

	local backup = nil

	if fs.exists(target) or fs.is_symlink(target) then
		if fs.is_symlink(target) then
			local current = fs.readlink(target)
			local normalized_current = normalize_path(current, machine.os.type)
			local normalized_source = normalize_path(source, machine.os.type)
			if normalized_current and normalized_current == normalized_source then
				c.dim("[linker] already linked: " .. target .. " -> " .. source)
				return true, "already linked"
			end
			c.tag_warn("linker", "replacing existing symlink: " .. target .. " (current: " .. (current or "unknown") .. ")")
			local removed, err = fs.remove_path(target)
			if not removed then return false, err end
		else
			-- Real file/directory: rename to backup so we can restore if symlinking fails
			backup = target .. ".dotbak"
			c.tag_warn("linker", "replacing existing target: " .. target)
			local ok, err = os.rename(target, backup)
			if not ok then
				return false, "Could not move existing target to backup: " .. (err or "unknown")
			end
		end
	end

	fs.mkdir_p(target)

	local cmd
	if machine.os.type == "unix" then
		cmd = string.format('ln -s "%s" "%s"', source, target)
	else
		if fs.is_directory(source) then
			cmd = string.format('cmd /c mklink /D "%s" "%s"', target:gsub("/", "\\"), source:gsub("/", "\\"))
		else
			cmd = string.format('cmd /c mklink "%s" "%s"', target:gsub("/", "\\"), source:gsub("/", "\\"))
		end
	end

	local result = os.execute(cmd)
	-- A standard Windows symlink needs Developer Mode or elevation.  Junctions
	-- and hard links provide the same behaviour for our local dotfiles without
	-- that prerequisite.
	if (result ~= 0 and result ~= true) and machine.os.type == "windows" then
		if fs.is_directory(source) then
			cmd = string.format('cmd /c mklink /J "%s" "%s"', target:gsub("/", "\\"), source:gsub("/", "\\"))
		else
			cmd = string.format('cmd /c mklink /H "%s" "%s"', target:gsub("/", "\\"), source:gsub("/", "\\"))
		end
		result = os.execute(cmd)
	end
	if result == 0 or result == true then
		if backup then
			c.tag_warn("linker", "previous target retained at: " .. backup)
		end
		c.tag_ok("linker", "linked: " .. target .. " -> " .. source)
		return true
	end

	-- Symlink failed — restore backup if we have one
	if backup then
		local restored, _ = os.rename(backup, target)
		if restored then
			return false, "Failed to create symlink (run as admin or enable Developer Mode) — original restored"
		else
			return false, "Failed to create symlink AND failed to restore backup at: " .. backup
		end
	end
	return false, "Failed to create symlink"
end

-- Create a Windows .lnk shortcut at `target` pointing to `source`.
-- Unlike a symlink, a shortcut is not a reparse point. Windows 11 build 26200+
-- silently skips reparse points when processing autostart locations, so
-- Startup entries must be real files. This is how we drop launchers into the
-- Startup folder without tripping that regression.
function M.link_shortcut(source, target)
	if not machine then M.init() end

	if machine.os.type ~= "windows" then
		return false, "Shortcuts are only supported on Windows"
	end
	if not source or not target then
		return false, "Source and target are required"
	end
	if not fs.exists(source) then
		return false, "Source does not exist: " .. source
	end

	-- Shortcut already points at the source?
	if fs.exists(target) and not fs.is_symlink(target) then
		local current = read_shortcut_target(target)
		if current and normalize_path(current, "windows") == normalize_path(source, "windows") then
			c.dim("[linker] already linked: " .. target .. " -> " .. source)
			return true, "already linked"
		end
	end

	local backup = nil
	if fs.exists(target) or fs.is_symlink(target) then
		if fs.is_symlink(target) then
			c.tag_warn("linker", "replacing existing symlink: " .. target)
			local removed, err = fs.remove_path(target)
			if not removed then return false, err end
		else
			backup = target .. ".dotbak"
			c.tag_warn("linker", "replacing existing target: " .. target)
			local ok, err = os.rename(target, backup)
			if not ok then
				return false, "Could not move existing target to backup: " .. (err or "unknown")
			end
		end
	end

	fs.mkdir_p(target)

	local win_target = target:gsub("/", "\\"):gsub("'", "''")
	local win_source = source:gsub("/", "\\"):gsub("'", "''")
	local work_dir = (source:gsub("/", "\\"):match("(.+)\\[^\\]+$") or ""):gsub("'", "''")

	local ps = "$w = New-Object -ComObject WScript.Shell; $s = $w.CreateShortcut('"
		.. win_target
		.. "'); $s.TargetPath = '"
		.. win_source
		.. "'; $s.WorkingDirectory = '"
		.. work_dir
		.. "'; $s.Save()"

	local result = os.execute('powershell -NoProfile -Command "' .. ps .. '"')
	if result == 0 or result == true then
		if backup then
			c.tag_warn("linker", "previous target retained at: " .. backup)
		end
		c.tag_ok("linker", "linked: " .. target .. " -> " .. source)
		return true
	end

	if backup then
		os.rename(backup, target)
	end
	return false, "Failed to create shortcut: " .. target
end

-- Remove a path (real file or symlink) if it exists. Used to clear legacy
-- launcher entries that are no longer valid.
function M.remove(path)
	if not machine then M.init() end
	if fs.exists(path) or fs.is_symlink(path) then
		return fs.remove_path(path)
	end
	return true
end

-- Link using variable names from shell/vars
function M.link_var(source_var, target_var)
	if not machine then M.init() end
	local source, err1 = resolver.resolve(source_var)
	if not source then
		return false, "Could not resolve source var '" .. source_var .. "': " .. (err1 or "unknown")
	end

	local target, err2 = resolver.resolve(target_var)
	if not target then
		return false, "Could not resolve target var '" .. target_var .. "': " .. (err2 or "unknown")
	end

	return M.link(source, target)
end

-- Links module dir to its system location using convention: {name}Dotfiles and system{Name}
-- (the dotfiles-side var is suffixed with "Dotfiles" so it never collides with
-- real environment variables the tool itself sets, e.g. TMUX, ZELLIJ)
function M.link_module(module_name)
	if not machine then M.init() end
	local source_var = module_name .. "Dotfiles"
	local system_var = "system" .. module_name:sub(1, 1):upper() .. module_name:sub(2)
	return M.link_var(source_var, system_var)
end

M.dotfiles_dir = dotfiles_dir

return M
