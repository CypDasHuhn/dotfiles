local c = require("colors")

local function trim(value)
	return value and value:match("^%s*(.-)%s*$") or ""
end

local function expand_home(path)
	if path == "~" then
		return os.getenv("HOME")
	end
	return path:gsub("^~/", (os.getenv("HOME") or "") .. "/")
end

local function excludes_file()
	local handle = io.popen("git config --global --get core.excludesFile 2>/dev/null")
	local configured = handle and trim(handle:read("*l"))
	if handle then handle:close() end

	if configured and configured ~= "" then
		if configured:match("^/") or configured:match("^~") then
			return expand_home(configured)
		end
		return (os.getenv("HOME") or "") .. "/" .. configured
	end

	local config_home = os.getenv("XDG_CONFIG_HOME")
	if not config_home or config_home == "" then
		config_home = (os.getenv("HOME") or "") .. "/.config"
	end
	return config_home .. "/git/ignore"
end

local target = excludes_file()
local parent = target:match("(.+)/[^/]+$")
if not parent then
	c.tag_err("gitignore", "could not determine global excludes directory")
	return
end

local mkdir_result = os.execute('mkdir -p "' .. parent:gsub('"', '\\"') .. '"')
if mkdir_result ~= 0 and mkdir_result ~= true then
	c.tag_err("gitignore", "could not create " .. parent)
	return
end

local file = io.open(target, "a+")
if not file then
	c.tag_err("gitignore", "could not open " .. target)
	return
end

file:seek("set", 0)
local content = file:read("*a") or ""
for line in (content .. "\n"):gmatch("([^\n]*)\n") do
	if trim(line) == "TODO-QUEUE.md" then
		file:close()
		c.dim("[gitignore] TODO-QUEUE.md already ignored in " .. target)
		return
	end
end

file:write((content ~= "" and not content:match("\n$")) and "\n" or "")
file:write("# Agent-local task queue; managed by dotfiles bootstrap\nTODO-QUEUE.md\n")
file:close()
c.tag_ok("gitignore", "added TODO-QUEUE.md to " .. target)
