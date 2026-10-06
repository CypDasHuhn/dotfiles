local link_skills = require("link_skills")

return function(linker)
	link_skills.link_tool(linker, "cursor-cli", "/.cursor", "/.cursor/skills")
end
