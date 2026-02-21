#!/usr/bin/env lua

-- Terminal Emulator Config Generator
-- Combines base config + generated keybinds

local M = {}

-- Get the script directory
local function get_script_dir()
	local info = debug.getinfo(1, "S")
	local path = info.source:match("^@(.*/)")
	return path or "./"
end

local script_dir = get_script_dir()

-- Load a lua file
local function load_file(path)
	local fn, err = loadfile(path)
	if not fn then
		return nil, err
	end
	return fn()
end

-- Read entire file as string
local function read_file(path)
	local f = io.open(path, "r")
	if not f then
		return nil, "Could not open file: " .. path
	end
	local content = f:read("*a")
	f:close()
	return content
end

-- Write string to file
local function write_file(path, content)
	local f = io.open(path, "w")
	if not f then
		return false, "Could not write to: " .. path
	end
	f:write(content)
	f:close()
	return true
end

-- Load keybinds source of truth
function M.load_keybinds()
	local path = script_dir .. "keybinds.lua"
	local keybinds, err = load_file(path)
	if not keybinds then
		return nil, "Failed to load keybinds: " .. (err or "unknown")
	end
	return keybinds
end

-- Load an emulator adapter
function M.load_emulator(name)
	local path = script_dir .. "emulators/" .. name .. ".lua"
	local emulator, err = load_file(path)
	if not emulator then
		return nil, "Failed to load emulator '" .. name .. "': " .. (err or "unknown")
	end
	return emulator
end

-- Load base config file
function M.load_base(name)
	-- Try common extensions
	local extensions = { "json", "shortcuts", "conf", "toml", "lua", "txt", "" }
	for _, ext in ipairs(extensions) do
		local filename = ext ~= "" and (name .. "." .. ext) or name
		local path = script_dir .. "base/" .. filename
		local content = read_file(path)
		if content then
			return content, filename
		end
	end
	return nil, "No base file found for: " .. name
end

-- Generate config for a specific emulator
-- Returns: generated content, or nil + error
function M.generate(emulator_name, output_path)
	-- Load keybinds
	local keybinds, kb_err = M.load_keybinds()
	if not keybinds then
		return nil, kb_err
	end

	-- Load emulator adapter
	local emulator, em_err = M.load_emulator(emulator_name)
	if not emulator then
		return nil, em_err
	end

	-- Load base config
	local base_content, base_file = M.load_base(emulator_name)
	if not base_content then
		return nil, base_file -- base_file contains error message
	end

	-- Generate keybinds block
	local keybinds_block = emulator.generate(keybinds)

	-- Replace the KEYBINDS-REPLACE marker
	-- Match any line containing KEYBINDS-REPLACE (ignoring comment prefixes)
	local result = base_content:gsub("[^\n]*KEYBINDS%-REPLACE[^\n]*", keybinds_block)

	-- Write output if path provided
	if output_path then
		local ok, write_err = write_file(output_path, result)
		if not ok then
			return nil, write_err
		end
		print("[terminal] Generated: " .. output_path)
	end

	return result
end

-- List available emulators
function M.list_emulators()
	local emulators = {}
	local handle = io.popen('ls -1 "' .. script_dir .. 'emulators/" 2>/dev/null')
	if handle then
		for file in handle:lines() do
			local name = file:match("(.+)%.lua$")
			if name then
				table.insert(emulators, name)
			end
		end
		handle:close()
	end
	return emulators
end

-- CLI interface
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
