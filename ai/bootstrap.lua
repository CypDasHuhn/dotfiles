-- Module bootstrap: link the shared AI skills in ai/skills/<name>/SKILL.md into
-- each installed tool's own skills directory (opencode, claude, codex,
-- copilot-cli). Tools that are not installed on the current machine are skipped.
local c = require("colors")
local linker = require("linker")

package.path = linker.dotfiles_dir .. "ai/tools/?.lua;" .. package.path

local tools = { "opencode", "claude", "codex", "copilot-cli" }
for _, name in ipairs(tools) do
	local ok, mod = pcall(require, name)
	if not ok or type(mod) ~= "function" then
		c.tag_warn("ai/" .. name, "could not load tool linker: " .. tostring(mod))
	else
		local ran, err = pcall(mod, linker)
		if not ran then
			c.tag_err("ai/" .. name, "linker failed: " .. tostring(err))
		end
	end
end
