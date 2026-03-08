local linker = require("linker")

if linker.machine().os.type ~= "unix" then return end

local home = os.getenv("HOME")
local zen_config_dir = home .. "/.config/zen"
local profiles_ini = zen_config_dir .. "/profiles.ini"

local function find_profile_path()
	local f = io.open(profiles_ini, "r")
	if not f then
		print("[zen] profiles.ini not found, skipping")
		return nil
	end
	local content = f:read("*all")
	f:close()

	local in_target = false
	for line in content:gmatch("[^\n]+") do
		if line:match("^%[") then
			in_target = false
		end
		if line:match("^Name=Default %(release%)") then
			in_target = true
		end
		if in_target then
			local path = line:match("^Path=(.+)")
			if path then return path end
		end
	end

	print("[zen] Could not find 'Default (release)' profile in profiles.ini")
	return nil
end

local profile_path = find_profile_path()
if not profile_path then return end

local profile_dir = zen_config_dir .. "/" .. profile_path
local zen_dir = linker.resolve("zen")

local files = {
	"zen-keyboard-shortcuts.json",
	"user.js",
}

for _, file in ipairs(files) do
	local ok, err = linker.link(zen_dir .. "/" .. file, profile_dir .. "/" .. file)
	if not ok and err ~= "already linked" then
		print("[zen] " .. file .. ": " .. (err or "failed"))
	end
end
