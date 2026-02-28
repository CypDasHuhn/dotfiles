local linker = require("linker")
package.path = linker.dotfiles_dir .. "terminal-emulator/?.lua;" .. package.path
local generator = require("generator")

return function(os_type, config_var, gen_name, system_var)
	if linker.machine().os.type ~= os_type then return end

	local output = linker.resolve(config_var)
	if output then
		local ok, err = generator.generate(gen_name, output)
		if not ok then print(gen_name .. ": generation failed - " .. err) return end
	end

	local ok, err = linker.link_var(config_var, system_var)
	if not ok and err ~= "already linked" then print(gen_name .. ": " .. (err or "link failed")) end
end
