local utils = require("utils")

local M = {}

local function is_windows()
	return package.config:sub(1, 1) == "\\"
end

local function quote_arg(arg)
	return '"' .. tostring(arg):gsub('"', '\\"') .. '"'
end

-- Expand remaining shell env var references (e.g. $HOME) to their actual values.
-- This is needed because nushell does not expand $VAR in plain strings at runtime.
local function expand_env_vars(value)
	return value:gsub("%$([A-Za-z_][A-Za-z0-9_]*)", function(name)
		local val = os.getenv(name) or os.getenv(name:upper())
		-- On Windows, $HOME may not be set; fall back to USERPROFILE
		if not val and name:upper() == "HOME" then
			val = os.getenv("USERPROFILE")
		end
		if val then
			return val:gsub("\\", "/")
		end
		return "$" .. name
	end)
end

local function ensure_source_line(config_path, stable_path)
	local source_line = 'source "' .. stable_path .. '"'

	local f = io.open(config_path, "r")
	if not f then
		f = io.open(config_path, "w")
		if not f then
			return false, "Could not create " .. config_path
		end
		f:write("# Dotfiles profile\n" .. source_line .. "\n")
		f:close()
		print("Created nushell config with source line")
		return true
	end

	local content = f:read("*a")
	f:close()

	-- Check for an active (uncommented) source line pointing to the stable path
	for line in (content .. "\n"):gmatch("([^\n]*)\n") do
		local trimmed = line:match("^%s*(.-)%s*$")
		if trimmed == source_line then
			print("Nushell config already sources profile")
			return true
		end
	end

	f = io.open(config_path, "a")
	if not f then
		return false, "Could not write to " .. config_path
	end
	f:write("\n# Dotfiles profile\n" .. source_line .. "\n")
	f:close()

	print("Added source line to nushell config")
	return true
end

function M.link(output_dir)
	local abs_dir
	if is_windows() then
		if output_dir:match("^%a:") then
			abs_dir = output_dir:gsub("\\", "/")
		else
			local handle = io.popen("cd")
			local cwd = handle and handle:read("*l") or ""
			if handle then handle:close() end
			cwd = cwd:gsub("\r", ""):gsub("\\", "/")
			abs_dir = cwd .. "/" .. output_dir:gsub("^[./\\]+", "")
		end
	else
		local handle = io.popen('cd ' .. quote_arg(output_dir) .. ' && pwd')
		abs_dir = handle and handle:read("*l") or output_dir
		if handle then handle:close() end
	end

	local profile = abs_dir .. "/profile.nu"

	-- On Windows nushell uses %APPDATA%\nushell\, on Unix ~/.config/nushell/
	local config_dir
	if is_windows() then
		local appdata = (os.getenv("APPDATA") or ""):gsub("\\", "/")
		if appdata == "" then
			return false, "APPDATA not set"
		end
		config_dir = appdata .. "/nushell"
		os.execute('cmd /c if not exist ' .. quote_arg(config_dir:gsub("/", "\\")) ..
			' mkdir ' .. quote_arg(config_dir:gsub("/", "\\")))
	else
		local home = os.getenv("HOME")
		-- If running under sudo, use the real user's home instead of root's
		local sudo_user = os.getenv("SUDO_USER")
		if sudo_user and sudo_user ~= "" then
			local handle = io.popen("getent passwd " .. sudo_user .. " 2>/dev/null | cut -d: -f6")
			if handle then
				local real_home = handle:read("*l")
				handle:close()
				if real_home and real_home ~= "" then
					home = real_home
				end
			end
		end
		if not home then
			return false, "HOME not set"
		end
		config_dir = home .. "/.config/nushell"
		os.execute('mkdir -p ' .. quote_arg(config_dir))
	end

	-- Use a stable symlink/shim at a fixed path in the nushell config dir.
	-- This means config.nu always sources the same path regardless of where
	-- the dotfiles repo is cloned, and the link stays valid across regenerations.
	local stable_path = config_dir .. "/dotfiles.nu"

	if is_windows() then
		-- On Windows: write a shim that sources the generated profile
		local f = io.open(stable_path, "w")
		if not f then
			return false, "Could not write shim to " .. stable_path
		end
		f:write('source "' .. profile .. '"\n')
		f:close()
		print("Written shim: " .. stable_path .. " -> " .. profile)
	else
		-- On Unix: create a symlink
		os.execute('ln -sf ' .. quote_arg(profile) .. ' ' .. quote_arg(stable_path))
		print("Linked: " .. stable_path .. " -> " .. profile)
	end

	ensure_source_line(config_dir .. "/config.nu", stable_path)
	return true
end

local function get_module_files(dir, extension)
	local files = {}
	local handle
	if is_windows() then
		local function quote_cmd_arg(arg)
			return '"' .. tostring(arg):gsub('"', '\\"') .. '"'
		end
		handle = io.popen('cmd /c dir /b /s /a-d ' ..
			quote_cmd_arg(dir:gsub("/", "\\")) .. " 2>nul")
		if not handle then return files end
		for file in handle:lines() do
			local clean = file:gsub("\r", ""):gsub("\\", "/")
			if clean:match("%" .. extension .. "$") then
				table.insert(files, clean)
			end
		end
	else
		handle = io.popen('find ' .. quote_arg(dir) .. ' -name "*' .. extension .. '" -type f 2>/dev/null')
		if not handle then return files end
		for file in handle:lines() do
			table.insert(files, file)
		end
	end
	handle:close()
	return files
end

local function get_filename(path)
	return path:match("([^/]+)$")
end

local function get_basename(path)
	return path:match("([^/]+)$"):match("(.+)%.[^.]+$")
end

local function get_dir(path)
	return path:match("(.+)/[^/]+$") or "."
end

local function generate_path_file(paths, vars, machine, output_dir)
	local shell_type = "nushell"
	local visual_type = machine.os and machine.os.visual

	local path_entries = {}
	for _, entry in ipairs(paths) do
		if utils.should_include(entry, machine.name, shell_type, visual_type) then
			local value = entry[1]
			value = utils.expand_value(value, vars, machine.name, shell_type)
			value = expand_env_vars(value)
			value = utils.normalize_path(value, shell_type)
			value = value:gsub('"', '\\"')
			table.insert(path_entries, '\t"' .. value .. '"')
		end
	end

	local lines = {
		"# Auto-generated by shell/run.lua",
		"# Do not edit manually",
		"",
	}

	if #path_entries > 0 then
		table.insert(lines, "$env.PATH = ($env.PATH | split row (char esep) | prepend [")
		for _, e in ipairs(path_entries) do
			table.insert(lines, e)
		end
		table.insert(lines, "])")
	end

	table.insert(lines, "")

	local output_path = output_dir .. "/path.nu"
	local ok, err = utils.write_file(output_path, table.concat(lines, "\n"))
	return ok, err, output_path
end

function M.generate(vars, var_order, machine, modules_dir, output_dir, paths)
	local abs_modules_dir
	if is_windows() then
		if modules_dir:match("^%a:") then
			-- Already absolute
			abs_modules_dir = modules_dir:gsub("\\", "/")
		else
			-- Relative: combine with CWD
			local h = io.popen("cd")
			local cwd = h and h:read("*l") or ""
			if h then h:close() end
			cwd = cwd:gsub("\r", ""):gsub("\\", "/")
			abs_modules_dir = cwd .. "/" .. modules_dir:gsub("^[./\\]+", ""):gsub("\\", "/")
		end
	else
		local handle = io.popen('cd ' .. quote_arg(modules_dir) .. ' && pwd')
		abs_modules_dir = handle and handle:read("*l") or modules_dir
		if handle then handle:close() end
	end

	local lines = {
		"# Auto-generated by shell/run.lua",
		"# Machine: " .. machine.name,
		"# Do not edit manually",
		"",
		"# Environment variables",
	}

	local shell_type = "nushell"
	local visual_type = machine.os and machine.os.visual
	local dir_functions = {}

	-- Nushell profile uses fully-expanded literal values so variable order doesn't
	-- matter at runtime. We still iterate in dependency order for consistency.
	for _, name in ipairs(var_order) do
		local var_def = vars[name]
		if utils.should_include(var_def, machine.name, shell_type, visual_type) then
			local value = utils.resolve_value(var_def, machine.name, shell_type)
			if value then
				-- Fully expand dotfiles variable references
				value = utils.expand_value(value, vars, machine.name, shell_type)
				-- Expand remaining shell env vars (e.g. $HOME) to literal paths
				value = expand_env_vars(value)
				-- Normalize to forward slashes
				value = utils.normalize_path(value, shell_type)
				value = value:gsub('"', '\\"')
				table.insert(lines, string.format('$env.%s = "%s"', name, value))
				if utils.has_dir_function(var_def) then
					table.insert(dir_functions, name)
				end
			end
		end
	end

	if #dir_functions > 0 then
		table.insert(lines, "")
		table.insert(lines, "# Directory navigation functions")
		for _, name in ipairs(dir_functions) do
			table.insert(lines, string.format("def --env %s [] {\n  cd $env.%s\n}", name, name))
		end
	end

	local platform_dir = abs_modules_dir .. "/nushell"
	local module_files = get_module_files(platform_dir, ".nu")
	local included_modules = {}
	local dir_meta_cache = {}

	for _, file in ipairs(module_files) do
		local basename = get_basename(file)
		local dir = get_dir(file)

		-- Load dir.lua once per directory
		if dir_meta_cache[dir] == nil then
			dir_meta_cache[dir] = utils.load_file(dir .. "/dir.lua") or false
		end

		-- File-level sidecar takes precedence over dir.lua
		local meta = utils.load_file(file .. ".lua") or dir_meta_cache[dir]

		local include = true
		if meta then
			include = utils.should_include(meta, machine.name, shell_type, visual_type)
		end

		if include then
			table.insert(included_modules, { file = file, name = basename })
		end
	end

	if #included_modules > 0 then
		table.insert(lines, "")
		table.insert(lines, "# Modules")
		for _, mod in ipairs(included_modules) do
			table.insert(lines, 'source "' .. mod.file .. '"')
		end
	end

	if paths and #paths > 0 then
		if is_windows() then
			os.execute('cmd /c if not exist ' .. quote_arg(output_dir:gsub("/", "\\")) .. ' mkdir ' .. quote_arg(output_dir:gsub("/", "\\")))
		else
			os.execute("mkdir -p " .. quote_arg(output_dir))
		end
		local path_ok, _, path_file = generate_path_file(paths, vars, machine, output_dir)
		if path_ok then
			-- Resolve to absolute path for the source line
			local abs_output_dir
			if is_windows() then
				if output_dir:match("^%a:") then
					abs_output_dir = output_dir:gsub("\\", "/")
				else
					local h = io.popen("cd")
					local cwd = h and h:read("*l") or ""
					if h then h:close() end
					cwd = cwd:gsub("\r", ""):gsub("\\", "/")
					abs_output_dir = cwd .. "/" .. output_dir:gsub("^[./\\]+", ""):gsub("\\", "/")
				end
			else
				local handle = io.popen('cd ' .. quote_arg(output_dir) .. ' && pwd')
				abs_output_dir = handle and handle:read("*l") or output_dir
				if handle then handle:close() end
			end
			table.insert(lines, "")
			table.insert(lines, "# PATH")
			table.insert(lines, 'source "' .. abs_output_dir .. '/path.nu"')
		end
	end

	table.insert(lines, "")

	local content = table.concat(lines, "\n")
	local output_path = output_dir .. "/profile.nu"

	local ok, err = utils.write_file(output_path, content)
	if not ok then
		return false, err
	end

	return true, output_path, #included_modules
end

return M
