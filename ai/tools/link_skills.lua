-- Shared helper for linking ai/skills/<name> into a tool's own skills directory.
-- Skills are symlinked individually (never the whole dir) so they coexist with
-- any skills the tool/user already has there.

local c = require("colors")

local M = {}

local function is_windows()
	return package.config:sub(1, 1) == "\\"
end

local function dir_exists(path)
	if not path then
		return false
	end
	local handle
	if is_windows() then
		handle = io.popen('cmd /c if exist "' .. path:gsub("/", "\\") .. '\\NUL" (echo yes) else (echo no)')
	else
		handle = io.popen('test -d "' .. path .. '" && echo yes || echo no')
	end
	if not handle then
		return false
	end
	local result = handle:read("*l")
	handle:close()
	return result == "yes"
end

-- Make a path absolute. linker.dotfiles_dir can be relative when the bootstrap
-- is invoked with a relative path (e.g. `lua bootstrap.lua`); symlinks must
-- always point at an absolute source so they resolve from any location.
function M.absolutize(path)
	if not path then
		return nil
	end
	if is_windows() then
		if path:match("^%a:") then
			return path
		end
	elseif path:sub(1, 1) == "/" then
		return path
	end
	local handle = io.popen(is_windows() and "cd" or "pwd")
	if not handle then
		return path
	end
	local cwd = handle:read("*l")
	handle:close()
	if not cwd or cwd == "" then
		return path
	end
	local stripped = path:gsub("^%.?[/\\]", "")
	return (cwd .. "/" .. stripped):gsub("/infra/%.%./", "/")
end

local function list_skills(root)
	local skills = {}
	local handle
	if is_windows() then
		handle = io.popen('cmd /c dir /b /ad "' .. root:gsub("/", "\\") .. '"')
	else
		handle = io.popen('ls -1 "' .. root .. '"')
	end
	if not handle then
		return skills
	end
	for line in handle:lines() do
		local name = line:gsub("\r$", "")
		if name ~= "" then
			local f = io.open(root .. "/" .. name .. "/SKILL.md", "r")
			if f then
				f:close()
				table.insert(skills, name)
			end
		end
	end
	handle:close()
	return skills
end

-- Resolve the user's home directory for the current machine.
function M.home(machine)
	if machine and machine.os and machine.os.type == "windows" then
		return os.getenv("USERPROFILE") or os.getenv("HOME")
	end
	return os.getenv("HOME")
end

-- Link every skill in ai/skills into `home .. skills_rel`, but only when the
-- tool is actually installed (its config dir `home .. base_rel` exists).
function M.link_tool(linker, tool_name, base_rel, skills_rel)
	local home = M.home(linker.machine())
	if not home then
		c.tag_warn("ai/" .. tool_name, "could not determine home directory; skipping")
		return
	end

	local base_dir = home .. base_rel
	if not dir_exists(base_dir) then
		c.tag_warn("ai/" .. tool_name, "not installed (" .. base_dir .. " missing); skipping")
		return
	end

	local skills_root = M.absolutize(linker.dotfiles_dir) .. "ai/skills"
	local target_root = home .. skills_rel
	for _, name in ipairs(list_skills(skills_root)) do
		local ok, err = linker.link(skills_root .. "/" .. name, target_root .. "/" .. name)
		if not ok and err ~= "already linked" then
			c.tag_warn("ai/" .. tool_name, name .. ": " .. (err or "link failed"))
		end
	end
	c.tag_ok("ai/" .. tool_name, "linked skills -> " .. target_root)
end

return M
