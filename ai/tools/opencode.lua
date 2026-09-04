-- opencode: skills are read from ~/.config/opencode/skills
local link_skills = require("link_skills")

return function(linker)
	link_skills.link_tool(linker, "opencode", "/.config/opencode", "/.config/opencode/skills")
end
