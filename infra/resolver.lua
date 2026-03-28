-- Variable resolver module
-- Usage: local resolver = require("resolver").new(vars, machine, utils)

local function new(vars, machine, utils)
	local M = {}
	local os_type = machine.os.type

	function M.expand_env(path)
		if not path then
			return nil
		end
		if os_type == "unix" then
			path = path:gsub("%$HOME", os.getenv("HOME") or "")
			path = path:gsub("%$([%w_]+)", function(var)
				return os.getenv(var) or ("$" .. var)
			end)
		else
			path = path:gsub("%%([^%%]+)%%", function(var)
				return os.getenv(var) or ("%" .. var .. "%")
			end)
			path = path:gsub("%$HOME", os.getenv("USERPROFILE") or "")
		end
		return path
	end

	function M.resolve(var_name)
		local var_def = vars[var_name]
		if not var_def then
			return nil, "Variable not found: " .. var_name
		end

		local visual_type = machine.os and machine.os.visual
		if not utils.should_include(var_def, machine.name, os_type, visual_type) then
			return nil, "Variable excluded for this machine/OS/visual: " .. var_name
		end

		local value = utils.resolve_value(var_def, machine.name, os_type)
		if not value then
			return nil, "Could not resolve value for: " .. var_name
		end

		value = utils.expand_value(value, vars, machine.name, os_type)
		value = utils.process_value(value, os_type)
		value = M.expand_env(value)
		return value
	end

	return M
end

return { new = new }
