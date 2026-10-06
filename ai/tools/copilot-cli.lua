local link_skills = require("link_skills")
local c = require("colors")

local function link_hook(linker, source, target)
	local ok, err = linker.link(source, target)
	if not ok then
		c.tag_warn("ai/copilot-cli", err or ("could not link " .. target))
	end
end

return function(linker)
	local installed = link_skills.link_tool(linker, "copilot-cli", "/.copilot", "/.copilot/skills")
	if not installed then
		return
	end

	local home = link_skills.home(linker.machine())
	if not home then
		return
	end

	local root = link_skills.absolutize(linker.dotfiles_dir) .. "ai/hooks"
	link_hook(linker, root .. "/copilot-cli.json", home .. "/.copilot/hooks/prompt-history.json")
	link_hook(linker, root .. "/log_prompt.py", home .. "/.copilot/hooks/log_prompt.py")
end
