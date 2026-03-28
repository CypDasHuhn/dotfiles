-- Dependency resolver with condition-based ordering
local platform = require("platform")
local M = {}

-- Detect current environment
function M.detect_env()
	local env = {}

	env.os = platform.os_type()

	if env.os == "unix" then
		local distro = io.popen("cat /etc/os-release 2>/dev/null | grep '^ID=' | cut -d= -f2 | tr -d '\"'"):read("*l")
		env.distro = distro or "default"

		-- Also get distro family (ID_LIKE) for fallback
		local distro_like = io.popen("cat /etc/os-release 2>/dev/null | grep '^ID_LIKE=' | cut -d= -f2 | tr -d '\"'")
			:read("*l")
		env.distro_family = distro_like or nil
	else
		env.distro = "default"
		env.distro_family = nil
	end

	-- CPU architecture
	local arch = io.popen("uname -m 2>/dev/null"):read("*l")
	env.arch = arch or "default"

	return env
end

-- Extract command entry from a value (handles string, {command=...}, or nested)
local function extract_entry(val)
	if type(val) == "string" then
		return { command = val, condition = nil, verify = nil }
	elseif type(val) == "table" and val.command then
		return {
			command = rawget(val, "command"),
			condition = rawget(val, "condition"),
			verify = rawget(val, "verify"),
			once = rawget(val, "once"),
		}
	end
	return nil -- not a leaf, needs further traversal
end

-- Normalize a dependency entry to full form
function M.normalize(entry)
	local leaf = extract_entry(entry)
	if leaf then
		return {
			default = {
				default = {
					default = leaf,
				},
			},
		}
	end

	-- Otherwise it's an OS-level table, normalize each level
	local result = {}
	for os_key, os_val in pairs(entry) do
		local os_leaf = extract_entry(os_val)
		if os_leaf then
			result[os_key] = { default = { default = os_leaf } }
		else
			-- Distro-level table
			result[os_key] = {}
			for distro_key, distro_val in pairs(os_val) do
				local distro_leaf = extract_entry(distro_val)
				if distro_leaf then
					result[os_key][distro_key] = { default = distro_leaf }
				else
					-- Arch-level table
					result[os_key][distro_key] = {}
					for arch_key, arch_val in pairs(distro_val) do
						local arch_leaf = extract_entry(arch_val)
						if arch_leaf then
							result[os_key][distro_key][arch_key] = arch_leaf
						else
							-- Shouldn't happen, but fallback
							result[os_key][distro_key][arch_key] =
								{ command = tostring(arch_val), condition = nil, verify = nil }
						end
					end
				end
			end
		end
	end
	return result
end

-- Get the command for current environment with fallbacks
function M.get_command(normalized, env)
	local os_table = normalized[env.os] or normalized["default"]
	if not os_table then
		return nil
	end

	-- Try exact distro, then distro family, then default
	local distro_table = os_table[env.distro]
	if not distro_table and env.distro_family then
		-- Check each word in distro_family (e.g., "arch linux" -> try "arch", then "linux")
		for family in env.distro_family:gmatch("%S+") do
			distro_table = os_table[family]
			if distro_table then
				break
			end
		end
	end
	distro_table = distro_table or os_table["default"]
	if not distro_table then
		return nil
	end

	local arch_entry = distro_table[env.arch] or distro_table["default"]
	return arch_entry
end

-- Check if condition is met
function M.check_condition(condition)
	if not condition then
		return true
	end
	local result = os.execute(condition .. " >/dev/null 2>&1")
	return result == 0 or result == true
end

-- Resolve all dependencies with retry loop
function M.resolve(dependencies, max_cycles)
	max_cycles = max_cycles or 10
	local env = M.detect_env()

	local todo = {}
	local delayed = {}
	local skipped = {}
	local failed = {}
	local succeeded = {}

	-- Initialize todo list
	for name, entry in pairs(dependencies) do
		local normalized = M.normalize(entry)
		local cmd_entry = M.get_command(normalized, env)
		if cmd_entry and cmd_entry.command then
			table.insert(todo, {
				name = name,
				command = cmd_entry.command,
				condition = cmd_entry.condition,
				verify = cmd_entry.verify,
				once = cmd_entry.once,
			})
		else
			table.insert(skipped, {
				name = name,
				reason = "no command for " .. env.os .. "/" .. env.distro .. "/" .. env.arch,
			})
		end
	end

	local cycle = 0
	while #todo > 0 and cycle < max_cycles do
		cycle = cycle + 1
		print("\n=== Cycle " .. cycle .. " ===")

		delayed = {}
		for _, item in ipairs(todo) do
			if M.check_condition(item.condition) then
				if item.once and item.verify and M.check_condition(item.verify) then
					print("[SKIP] " .. item.name .. ": already installed")
					table.insert(succeeded, item.name)
					goto continue
				end

				print("[RUN] " .. item.name .. ": " .. item.command)
				local cmd_success = os.execute(item.command)
				cmd_success = (cmd_success == 0 or cmd_success == true)

				-- Verify if command succeeded and verify is defined
				local verified = true
				if cmd_success and item.verify then
					verified = M.check_condition(item.verify)
					if not verified then
						print("[VERIFY FAILED] " .. item.name)
					end
				end

				if cmd_success and verified then
					print("[OK] " .. item.name)
					table.insert(succeeded, item.name)
				else
					table.insert(failed, {
						name = item.name,
						reason = not cmd_success and "command failed" or "verification failed",
					})
				end
			else
				print("[DELAY] " .. item.name .. ": condition not met")
				table.insert(delayed, item)
			end
			::continue::
		end

		if #delayed == #todo then
			-- No progress, move remaining to failed
			for _, item in ipairs(delayed) do
				table.insert(failed, {
					name = item.name,
					reason = "condition never met: " .. (item.condition or "none"),
				})
			end
			break
		end

		todo = delayed
	end

	-- Summary
	print("\n=== Summary ===")
	if #succeeded > 0 then
		print("[OK] " .. #succeeded .. " installed successfully")
	end
	if #skipped > 0 then
		print("\n[SKIPPED] " .. #skipped .. " packages:")
		for _, item in ipairs(skipped) do
			print("  - " .. item.name .. ": " .. item.reason)
		end
	end
	if #failed > 0 then
		print("\n[FAILED] " .. #failed .. " packages:")
		for _, item in ipairs(failed) do
			print("  - " .. item.name .. ": " .. item.reason)
		end
	end
	if #skipped == 0 and #failed == 0 then
		print("[DONE] All dependencies resolved successfully")
	end
end

return M
