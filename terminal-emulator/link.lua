local linker = require("linker")
package.path = linker.dotfiles_dir .. "terminal-emulator/?.lua;" .. package.path
local generator = require("generator")

local function is_windows_terminal_session()
	return os.getenv("WT_SESSION")
		or os.getenv("WT_PROFILE_ID")
		or os.getenv("TERM_PROGRAM") == "Windows_Terminal"
end

return function(os_type, config_var, gen_name, system_var)
	if linker.machine().os.type ~= os_type then return end

	local output = linker.resolve(config_var)
	if output then
		local ok, err = generator.generate(gen_name, output)
		if not ok then print(gen_name .. ": generation failed - " .. err) return end
	end

	if gen_name == "windows-terminal" and is_windows_terminal_session() then
		print("[terminal] Windows Terminal detected; skipping link to avoid replacing settings.json. Run bootstrap from another terminal to relink.")
		return
	end

	local ok, err = linker.link_var(config_var, system_var)
	if not ok and err ~= "already linked" then print(gen_name .. ": " .. (err or "link failed")) end
end
