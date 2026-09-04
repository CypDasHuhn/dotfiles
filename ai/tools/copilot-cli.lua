-- GitHub Copilot CLI: skills are read from ~/.copilot/skills
-- NOTE: copilot is not installed on this machine yet; the actual skills dir may
-- differ. The presence check keeps this a no-op until copilot exists here, so it
-- can be corrected later without side effects.
local link_skills = require("link_skills")

return function(linker)
	link_skills.link_tool(linker, "copilot-cli", "/.copilot", "/.copilot/skills")
end
