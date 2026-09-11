-- Codex stores local skills under ~/.codex/skills by default. The presence
-- check keeps this a no-op on machines where Codex is not installed.
local link_skills = require("link_skills")

return function(linker)
	link_skills.link_tool(linker, "codex", "/.codex", "/.codex/skills")
end
