-- codex: skills are read from ~/.codex/skills
-- NOTE: codex is not installed on this machine yet; the actual skills dir may
-- differ. The presence check keeps this a no-op until codex exists here, so it
-- can be corrected later without side effects.
local link_skills = require("link_skills")

return function(linker)
	link_skills.link_tool(linker, "codex", "/.codex", "/.codex/skills")
end
