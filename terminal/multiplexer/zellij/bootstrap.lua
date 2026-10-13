local c = require("colors")
local linker = require("linker")

local function normalize(path)
	return path:gsub("\\", "/"):gsub("/+$", ""):lower()
end

local function read_link_target(path)
	local win_path = path:gsub("/", "\\"):gsub("'", "''")
	local command = "powershell -NoProfile -Command \"$item = Get-Item -Force -LiteralPath '"
		.. win_path
		.. "' -ErrorAction SilentlyContinue; if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { @($item.Target)[0] }\""
	local handle = io.popen(command)
	if not handle then
		return nil
	end
	local target = handle:read("*l")
	handle:close()
	return target and target ~= "" and target or nil
end

local function legacy_placeholder(path, source)
	local target = read_link_target(path)
	if target then
		return normalize(target) == normalize(source)
	end

	local file = io.open(path, "r")
	if not file then
		return false
	end
	local contents = file:read("*a")
	file:close()
	contents = contents:gsub("\r", ""):gsub("\n+$", "")
	return normalize(contents) == normalize(source)
end

local function migrate_legacy_windows_layout()
	if package.config:sub(1, 1) ~= "\\" then
		return true
	end

	local source = linker.resolve("zellijDotfiles")
	local target = linker.resolve("systemZellij")
	if not source or not target then
		return false, "could not resolve Zellij paths"
	end

	local parent = target:match("(.+)/[^/]+$")
	local parent_target = parent and read_link_target(parent) or nil
	if parent_target and normalize(parent_target) == normalize(source) then
		local removed, err = linker.remove(parent)
		if not removed then
			return false, "could not remove legacy Zellij directory link: " .. (err or "unknown")
		end
		c.tag("zellij", "removed legacy parent link")
	end

	for _, path in ipairs({ source .. "/config", source .. "/config.dotbak" }) do
		if legacy_placeholder(path, source) then
			local removed, err = linker.remove(path)
			if not removed then
				return false, "could not remove legacy artifact: " .. path .. ": " .. (err or "unknown")
			end
			c.tag("zellij", "removed legacy artifact -> " .. path)
		end
	end

	return true
end

local migrated, migration_err = migrate_legacy_windows_layout()
if not migrated then
	c.tag_err("zellij", migration_err)
	return
end

local ok, err = linker.link_module("zellij")
if ok then
	c.tag_ok("zellij", "linked")
elseif err ~= "already linked" then
	c.tag_err("zellij", err or "failed")
end
