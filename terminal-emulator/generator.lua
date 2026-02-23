#!/usr/bin/env lua

-- Terminal Emulator Config Generator

local M = {}

local function get_script_dir()
	local info = debug.getinfo(1, "S")
	local source = info and info.source or ""
	local path = source:match("^@(.+[\\/])")
	if path then
		return path:gsub("\\", "/")
	end
	return "./"
end

local script_dir = get_script_dir()

local function load_file(path)
	local fn, err = loadfile(path)
	if not fn then
		return nil, err
	end
	return fn()
end

local function read_file(path)
	local f = io.open(path, "r")
	if not f then
		return nil, "Could not open: " .. path
	end
	local content = f:read("*a")
	f:close()
	return content
end

local function write_file(path, content)
	local dir = path:match("(.+)/[^/]+$") or path:match("(.+)\\[^\\]+$")
	if dir then
		if package.config:sub(1, 1) == "\\" then
			local win_dir = dir:gsub("/", "\\")
			os.execute('cmd /c if not exist "' .. win_dir .. '" mkdir "' .. win_dir .. '"')
		else
			os.execute('mkdir -p "' .. dir .. '"')
		end
	end

	local f = io.open(path, "w")
	if not f then
		return false, "Could not write: " .. path
	end
	f:write(content)
	f:close()
	return true
end

function M.load_keybinds()
	return load_file(script_dir .. "keybinds.lua")
end

function M.load_mapper(name)
	return load_file(script_dir .. name .. "/mapper.lua")
end

function M.load_base(name)
	local extensions = { "json", "rc", "shortcuts", "conf", "toml", "lua", "txt" }
	for _, ext in ipairs(extensions) do
		local path = script_dir .. name .. "/base." .. ext
		local content = read_file(path)
		if content then
			return content
		end
	end
	return nil, "No base file found for: " .. name
end

function M.generate(emulator_name, output_path)
	local keybinds, kb_err = M.load_keybinds()
	if not keybinds then
		return nil, "Failed to load keybinds: " .. (kb_err or "unknown")
	end

	local mapper, map_err = M.load_mapper(emulator_name)
	if not mapper then
		return nil, "Failed to load mapper: " .. (map_err or "unknown")
	end

	local base_content, base_err = M.load_base(emulator_name)
	if not base_content then
		return nil, base_err
	end

	local keybinds_block = mapper.generate(keybinds)
	local result = base_content:gsub("[^\n]*KEYBINDS%-REPLACE[^\n]*", keybinds_block)

	if output_path then
		local ok, write_err = write_file(output_path, result)
		if not ok then
			return nil, write_err
		end
		print("[terminal] Generated: " .. output_path)
	end

	return result
end

function M.list_emulators()
	local emulators = {}
	local cmd
	if package.config:sub(1, 1) == "\\" then
		cmd = 'cmd /c dir /b /ad "' .. script_dir:gsub("/", "\\") .. '*" 2>nul'
	else
		cmd = 'ls -d "' .. script_dir .. '"*/ 2>/dev/null'
	end
	local handle = io.popen(cmd)
	if handle then
		for dir in handle:lines() do
			local name = dir:match("([^/\\]+)[/\\]?$")
			if name then
				local mapper = io.open(script_dir .. name .. "/mapper.lua", "r")
				if mapper then
					mapper:close()
					table.insert(emulators, name)
				end
			end
		end
		handle:close()
	end
	return emulators
end

if arg and arg[0] and arg[0]:match("generator%.lua$") then
	local emulator_name = arg[1]
	local output_path = arg[2]

	if not emulator_name then
		print("Usage: lua generator.lua <emulator> [output_path]")
		print("")
		print("Available emulators:")
		for _, name in ipairs(M.list_emulators()) do
			print("  " .. name)
		end
		os.exit(1)
	end

	local result, err = M.generate(emulator_name, output_path)
	if not result then
		print("Error: " .. err)
		os.exit(1)
	end

	if not output_path then
		print(result)
	end
end

return M
