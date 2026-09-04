-- claude code: skills are read from ~/.claude/skills
-- (opencode also auto-loads this directory as external skills.)
local link_skills = require("link_skills")

return function(linker)
	link_skills.link_tool(linker, "claude", "/.claude", "/.claude/skills")
end
