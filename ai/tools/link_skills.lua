-- Shared helper for linking skills in ai/skills into a tool's own skills dir.
--
-- Two source forms are supported so authoring stays flat until a skill needs
-- supporting files:
--   ai/skills/<name>.md         plain single-file skill
--   ai/skills/<name>/SKILL.md   skill with supporting files (folder wins if both)
--
-- Materialization at the tool side is always the loader contract the tools
-- expect (<name>/SKILL.md), so tools never need to know our authoring schema.
-- Links are per-skill so they coexist with any skills the tool already has.

local c = require("colors")

local M = {}

local function is_windows()
	return package.config:sub(1, 1) == "\\"
end

local function popen_line(cmd)
	local handle = io.popen(cmd)
	if not handle then
		return nil
	end
	local line = handle:read("*l")
	handle:close()
	return line
end

local function dir_exists(path)
	if not path then
		return false
	end
	if is_windows() then
		return popen_line('cmd /c if exist "' .. path:gsub("/", "\\") .. '\\NUL" (echo yes) else (echo no)') == "yes"
	end
	return popen_line('test -d "' .. path .. '" && echo yes || echo no') == "yes"
end

local function file_exists(path)
	if not path then
		return false
	end
	if is_windows() then
		return popen_line('cmd /c if exist "' .. path:gsub("/", "\\") .. '" (echo yes) else (echo no)') == "yes"
	end
	return popen_line('test -e "' .. path .. '" && echo yes || echo no') == "yes"
end

local function is_symlink(path)
	if is_windows() then
		return false
	end
	return popen_line('test -L "' .. path .. '" && echo yes || echo no') == "yes"
end

-- Remove a stale symlink we manage if it still points into the skills root
-- (e.g. an old whole-folder link after a skill switched to the flat form).
local function remove_managed_link(path, root)
	if not path or not is_symlink(path) then
		return
	end
	local target = popen_line('readlink "' .. path .. '"')
	if target and (target == root or target:sub(1, #root + 1) == root .. "/") then
		os.execute('rm -rf "' .. path .. '"')
	end
end

local function is_managed_target(target, root)
	if not is_symlink(target) then
		return false
	end
	local rl = popen_line('readlink "' .. target .. '"')
	return rl and (rl == root or rl:sub(1, #root + 1) == root .. "/")
end

-- Remove tool-side artifacts for skills that no longer exist in the repo.
local function prune_stale(target_root, skills_root, current)
	local handle
	if is_windows() then
		handle = io.popen('cmd /c dir /b "' .. target_root:gsub("/", "\\") .. '"')
	else
		handle = io.popen('ls -1 "' .. target_root .. '"')
	end
	if not handle then
		return
	end
	for line in handle:lines() do
		local name = line:gsub("\r$", "")
		if name ~= "" and not current[name] then
			local child = target_root .. "/" .. name
			if is_symlink(child) and is_managed_target(child, skills_root) then
				os.execute('rm -rf "' .. child .. '"')
			elseif is_managed_target(child .. "/SKILL.md", skills_root) then
				os.execute('rm -rf "' .. child .. '"')
			end
		end
	end
	handle:close()
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
	local cwd = popen_line(is_windows() and "cd" or "pwd")
	if not cwd or cwd == "" then
		return path
	end
	local stripped = path:gsub("^%.?[/\\]", "")
	return (cwd .. "/" .. stripped):gsub("/infra/%.%./", "/")
end

-- Enumerate skills. Folder skills are collected first; a flat <stem>.md is only
-- used when no folder skill with the same stem exists.
local function list_skills(root)
	local by_stem = {}
	local function add(entry)
		by_stem[entry.name] = entry
	end

	local handle
	if is_windows() then
		handle = io.popen('cmd /c dir /b "' .. root:gsub("/", "\\") .. '"')
	else
		handle = io.popen('ls -1 "' .. root .. '"')
	end
	if not handle then
		return {}
	end

	local names = {}
	for line in handle:lines() do
		local name = line:gsub("\r$", "")
		if name ~= "" then
			table.insert(names, name)
		end
	end
	handle:close()
	table.sort(names)

	for _, name in ipairs(names) do
		if file_exists(root .. "/" .. name .. "/SKILL.md") then
			add { name = name, kind = "folder", source = root .. "/" .. name }
		end
	end
	for _, name in ipairs(names) do
		local stem = name:match("^(.*)%.md$")
		if stem and not by_stem[stem] and file_exists(root .. "/" .. name) then
			add { name = stem, kind = "file", source = root .. "/" .. name }
		end
	end

	local entries = {}
	for _, entry in pairs(by_stem) do
		table.insert(entries, entry)
	end
	table.sort(entries, function(a, b)
		return a.name < b.name
	end)
	return entries
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
	local current = {}
	local entries = list_skills(skills_root)
	for _, entry in ipairs(entries) do
		current[entry.name] = true
	end
	for _, entry in ipairs(entries) do
		local target = target_root .. "/" .. entry.name
		local ok, err
		if entry.kind == "file" then
			remove_managed_link(target, skills_root)
			ok, err = linker.link(entry.source, target .. "/SKILL.md")
		else
			remove_managed_link(target .. "/SKILL.md", skills_root)
			ok, err = linker.link(entry.source, target)
		end
		if not ok and err ~= "already linked" then
			c.tag_warn("ai/" .. tool_name, entry.name .. ": " .. (err or "link failed"))
		end
	end
	prune_stale(target_root, skills_root, current)
	c.tag_ok("ai/" .. tool_name, "linked skills -> " .. target_root)
end

return M
