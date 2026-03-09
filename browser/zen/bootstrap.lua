local c = require("colors")
local linker = require("linker")

local function normalize(path)
	if not path then
		return nil
	end
	return path:gsub("\\", "/"):gsub("/+$", "")
end

local function file_exists(path)
	local f = io.open(path, "r")
	if f then
		f:close()
		return true
	end
	return false
end

local function find_config_dir()
	local os_type = linker.machine().os.type
	local candidates
	if os_type == "windows" then
		candidates = {
			normalize(os.getenv("APPDATA")) and (normalize(os.getenv("APPDATA")) .. "/zen") or nil,
			normalize(os.getenv("USERPROFILE")) and (normalize(os.getenv("USERPROFILE")) .. "/AppData/Roaming/zen") or nil,
			normalize(os.getenv("HOME")) and (normalize(os.getenv("HOME")) .. "/AppData/Roaming/zen") or nil,
		}
	else
		candidates = {
			normalize(os.getenv("HOME")) and (normalize(os.getenv("HOME")) .. "/.config/zen") or nil,
		}
	end

	for _, dir in ipairs(candidates) do
		local ini = dir and (dir .. "/profiles.ini") or nil
		if ini and file_exists(ini) then
			return dir, ini
		end
	end

	c.tag_warn("zen", "profiles.ini not found, skipping")
	return nil, nil
end

local function parse_profiles(profiles_ini)
	local f = io.open(profiles_ini, "r")
	if not f then
		return {}, nil
	end

	local profiles = {}
	local current = nil
	local install_default = nil
	local section_name = nil
	for raw in f:lines() do
		local line = raw:gsub("\r$", "")
		local section = line:match("^%[([^%]]+)%]$")
		if section then
			section_name = section
			if section:match("^Profile%d+$") then
				current = { section = section }
				table.insert(profiles, current)
			else
				current = nil
			end
		elseif current then
			local key, value = line:match("^([^=]+)=(.*)$")
			if key and value then
				current[key] = value
			end
		else
			local key, value = line:match("^([^=]+)=(.*)$")
			if
				section_name
				and section_name:match("^Install")
				and key == "Default"
				and value
				and value ~= ""
				and not install_default
			then
				install_default = normalize(value)
			end
		end
	end
	f:close()
	return profiles, install_default
end

local function choose_profile(profiles, install_default)
	local default_profile = nil
	local named_default = nil
	local first_profile = nil

	for _, profile in ipairs(profiles) do
		if profile.Path and profile.Path ~= "" then
			if install_default and normalize(profile.Path) == install_default then
				return profile
			end
			first_profile = first_profile or profile
			if profile.Default == "1" then
				default_profile = default_profile or profile
			end
			if profile.Name and profile.Name:lower():find("default", 1, true) then
				named_default = named_default or profile
			end
		end
	end

	return default_profile or named_default or first_profile
end

local function resolve_profile_dir(config_dir, profile)
	if not profile or not profile.Path or profile.Path == "" then
		return nil
	end

	local profile_path = normalize(profile.Path)
	if not profile_path then
		return nil
	end

	if profile_path:match("^/") or profile_path:match("^%a:[/]") then
		return profile_path
	end

	if profile.IsRelative == nil or profile.IsRelative == "1" then
		return config_dir .. "/" .. profile_path
	end

	return profile_path
end

local function copy_file(source, target)
	local src, src_err = io.open(source, "rb")
	if not src then
		return false, src_err or ("could not open source: " .. source)
	end

	local content = src:read("*all")
	src:close()
	if not content then
		return false, "could not read source: " .. source
	end

	local dst, dst_err = io.open(target, "wb")
	if not dst then
		return false, dst_err or ("could not open target: " .. target)
	end
	local ok, write_err = dst:write(content)
	dst:close()
	if not ok then
		return false, write_err or ("could not write target: " .. target)
	end
	return true
end

local zen_config_dir, profiles_ini = find_config_dir()
if not zen_config_dir then
	return
end

local profiles, install_default = parse_profiles(profiles_ini)
local profile = choose_profile(profiles, install_default)
if not profile then
	c.tag_err("zen", "could not find a profile with Path in profiles.ini")
	return
end

local profile_dir = resolve_profile_dir(zen_config_dir, profile)
if not profile_dir then
	c.tag_err("zen", "could not resolve profile directory from profiles.ini")
	return
end

local zen_dir = linker.dotfiles_dir .. "browser/zen"

local files = {
	"zen-keyboard-shortcuts.json",
	"user.js",
}

for _, file in ipairs(files) do
	local ok, err = linker.link(zen_dir .. "/" .. file, profile_dir .. "/" .. file)
	if ok then
		c.tag_ok("zen", "linked: " .. file)
	elseif err == "Failed to create symlink" then
		local copied, copy_err = copy_file(zen_dir .. "/" .. file, profile_dir .. "/" .. file)
		if copied then
			c.tag_warn("zen", "copied (symlink unavailable): " .. file)
		else
			c.tag_err("zen", file .. ": " .. (copy_err or "copy failed"))
		end
	elseif err ~= "already linked" then
		c.tag_err("zen", file .. ": " .. (err or "failed"))
	end
end

if profile.Name and profile.Name ~= "" then
	c.tag("zen", "profile: " .. profile.Name)
else
	c.tag("zen", "profile: " .. (profile.section or "unknown"))
end
if profile.Default == "1" then
	c.tag("zen", "default profile detected")
else
	c.tag_warn("zen", "linked non-default profile (no Default=1 flag)")
end
