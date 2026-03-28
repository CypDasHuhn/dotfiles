#!/usr/bin/env lua

local function get_script_dir()
	local source = (arg and arg[0]) or ""
	local path = source:match("(.+[\\/])")
	if path then
		return path:gsub("\\", "/")
	end
	return "./"
end
local script_dir = get_script_dir()

package.path = script_dir .. "infra/?.lua;" .. script_dir .. "terminal/emulator/?.lua;" .. package.path

local c = require("colors")
local cli = require("cli")
local machine_mod = require("machine")
local bootstrapper = require("bootstrapper")

local filter = arg and arg[1]

if filter == "--help" or filter == "-h" then
	cli.print_help()
	os.exit(0)
end

c.header("Dotfiles Bootstrap")
print("")

local function should_run(category)
	return cli.should_run(filter, category)
end

machine_mod.ensure(script_dir)

if should_run("shell") then
	c.section("Shell Configuration")
	local shell_result = os.execute('lua "' .. script_dir .. 'shell/run.lua"')
	if shell_result ~= 0 and shell_result ~= true then
		c.err("Shell generation failed")
		os.exit(1)
	end
	print("")
end

local ok, linker = pcall(require, "linker")
if not ok or not linker then
	c.err("Failed to load linker: " .. tostring(linker))
	os.exit(1)
end
linker.init()

if should_run("link") then
	c.section("Linking Modules")
	print("")
end

if should_run("modules") or cli.is_module_filter(filter, filter) then
	c.section("Module Bootstraps")
	for _, bootstrap_path in ipairs(bootstrapper.find(script_dir, linker.machine())) do
		local mod = bootstrap_path:match("/([^/]+)/bootstrap%.lua$")
			or bootstrap_path:match("\\([^\\]+)\\bootstrap%.lua$")
		if mod and (should_run("modules") or cli.is_module_filter(filter, mod)) then
			c.tag(mod, "running bootstrap...")
			dofile(bootstrap_path)
		end
	end
	print("")
end

if should_run("deps") then
	c.section("Dependencies")
	require("dependencies.init").run(script_dir)
	print("")
end

c.header("Bootstrap Complete")
