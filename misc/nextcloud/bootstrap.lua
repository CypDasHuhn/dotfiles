-- Sync this machine's vault with the self-hosted Nextcloud server.
--
-- Cross-platform:
--   Unix    -> headless `nextcloudcmd` driven by a systemd service + timer.
--              Credentials come from an EnvironmentFile generated out of the
--              gitignored secrets.lua at the dotfiles root
--              (key NEXTCLOUD_APP_PASSWORD).
--   Windows -> Nextcloud desktop client; account setup stays a manual GUI step
--              (there is no supported headless preconfiguration).
--
-- The deployment details are fixed here; the only external value is the app
-- password, read from the gitignored secrets.lua at the dotfiles root.

local c = require("colors")
local platform = require("platform")

local SERVER = "https://nextcloud.cypdashuhn.de"
local ACCOUNT = "cyp"
local SECRET_KEY = "NEXTCLOUD_APP_PASSWORD"
local TARGET_VAR = "vault"
local UNIT = "nextcloud-vault"
local ENV_FILE = "/etc/nextcloud-vault.env"

local os_type = platform.os_type()

local function script_dir()
	local source = debug.getinfo(1, "S").source:gsub("^@", "")
	return source:match("(.+)/[^/]+$") or "."
end

local function ok(result)
	return result == 0 or result == true
end

local function command_exists(bin)
	if os_type == "windows" then
		return ok(os.execute("where " .. bin .. " >NUL 2>NUL"))
	end
	return ok(os.execute("command -v " .. bin .. " >/dev/null 2>&1"))
end

local function file_exists(path)
	if os_type == "windows" then
		return ok(os.execute('if exist "' .. path:gsub("/", "\\") .. '" (exit 0) else (exit 1)'))
	end
	return ok(os.execute('test -e "' .. path .. '"'))
end

local function systemd_available()
	if os_type == "windows" then
		return false
	end
	return file_exists("/run/systemd/system") and command_exists("systemctl")
end

local function seafile_present()
	if os_type == "windows" then
		return command_exists("seafile-applet")
	end
	if command_exists("seaf-cli") or command_exists("seaf-daemon") then
		return true
	end
	local home = os.getenv("HOME")
	return home ~= nil and file_exists(home .. "/.ccnet")
end

-- One-time migration: a machine previously synced via Seafile must not keep
-- both clients running over the same vault folder.
local function decommission_seafile(user)
	if not seafile_present() then
		return
	end
	c.tag("nextcloud", "decommissioning Seafile client")
	if os_type == "windows" then
		os.execute("winget uninstall --silent Seafile.Seafile >NUL 2>NUL")
		return
	end
	if command_exists("systemctl") then
		os.execute("sudo systemctl disable --now seaf-cli@" .. user .. ".service 2>/dev/null")
	end
	if command_exists("pacman") then
		os.execute("sudo pacman -Rns --noconfirm seafile 2>/dev/null")
	end
	local home = os.getenv("HOME")
	if home then
		os.execute('rm -rf "' .. home .. '/.ccnet" "' .. home .. '/.local/share/seafile"')
	end
	c.tag_ok("nextcloud", "Seafile client removed")
end

local dir = script_dir()
local secrets = dir .. "/../../secrets.lua"

local function read_secret(key)
	local chunk = loadfile(secrets)
	if not chunk then
		return nil
	end
	local loaded, values = pcall(chunk)
	if not loaded or type(values) ~= "table" then
		return nil
	end
	local value = values[key]
	if type(value) == "string" and value ~= "" then
		return value
	end
	return nil
end

local function resolve_target()
	local target = require("linker").resolve(TARGET_VAR)
	if target then
		return target
	end
	local home = os.getenv("HOME") or os.getenv("USERPROFILE") or ""
	return home .. "/vault"
end

-- Write a root-owned file via sudo. Content goes through a user-writable temp
-- file so nothing needs shell quoting.
local function sudo_write(path, content, mode)
	local tmp = os.tmpname()
	local handle = io.open(tmp, "w")
	if not handle then
		return false
	end
	handle:write(content)
	handle:close()
	local result = ok(os.execute(string.format(
		"sudo install -o root -g root -m %s %q %q && rm -f %q",
		mode,
		tmp,
		path,
		tmp
	)))
	if not result then
		os.remove(tmp)
	end
	return result
end

local function service_unit(user, home, target)
	return string.format(
		"[Unit]\n"
			.. "Description=Sync %s with Nextcloud (nextcloudcmd)\n"
			.. "After=network-online.target\n"
			.. "Wants=network-online.target\n"
			.. "\n"
			.. "[Service]\n"
			.. "Type=oneshot\n"
			.. "User=%s\n"
			.. "Group=%s\n"
			.. "Environment=HOME=%s\n"
			.. "EnvironmentFile=%s\n"
			.. "ExecStart=/usr/bin/nextcloudcmd --non-interactive %s %s\n"
			.. "Nice=10\n"
			.. "IOSchedulingClass=idle\n",
		target,
		user,
		user,
		home,
		ENV_FILE,
		target,
		SERVER
	)
end

local function timer_unit()
	return "[Unit]\n"
		.. "Description=Periodic Nextcloud vault sync\n"
		.. "\n"
		.. "[Timer]\n"
		.. "OnBootSec=2min\n"
		.. "OnUnitActiveSec=3min\n"
		.. "AccuracySec=30s\n"
		.. "Persistent=true\n"
		.. "\n"
		.. "[Install]\n"
		.. "WantedBy=timers.target\n"
end

local function unix_sync()
	local user = os.getenv("USER") or os.getenv("LOGNAME")
	local home = os.getenv("HOME")
	if not user or not home then
		c.tag_err("nextcloud", "could not determine user/home")
		return
	end

	decommission_seafile(user)

	local password = read_secret(SECRET_KEY)
	if not password then
		c.tag_err("nextcloud", "missing " .. SECRET_KEY .. " in secrets.lua; cannot sync")
		return
	end

	local target = resolve_target()

	if not systemd_available() then
		c.tag_warn("nextcloud", "systemd unavailable; running a one-shot sync")
		os.execute(string.format(
			"NC_USER=%q NC_PASSWORD=%q nextcloudcmd --non-interactive %q %q",
			ACCOUNT,
			password,
			target,
			SERVER
		))
		return
	end

	c.tag("nextcloud", "writing " .. ENV_FILE)
	sudo_write(ENV_FILE, string.format("NC_USER=%s\nNC_PASSWORD=%s\n", ACCOUNT, password), "600")
	sudo_write("/etc/systemd/system/" .. UNIT .. ".service", service_unit(user, home, target), "644")
	sudo_write("/etc/systemd/system/" .. UNIT .. ".timer", timer_unit(), "644")

	os.execute("sudo systemctl daemon-reload")
	c.tag("nextcloud", "enabling " .. UNIT .. ".timer")
	os.execute("sudo systemctl enable --now " .. UNIT .. ".timer")
	os.execute("sudo systemctl start " .. UNIT .. ".service")
	c.tag_ok("nextcloud", "syncing " .. target .. " -> " .. SERVER)
end

local function windows_sync()
	decommission_seafile(os.getenv("USERNAME") or os.getenv("USER") or "")
	if not command_exists("nextcloud") then
		c.tag("nextcloud", "Nextcloud client not installed yet; run bootstrap deps")
		return
	end
	local target = resolve_target()
	c.tag_ok("nextcloud", "installed; log in as " .. ACCOUNT .. " and sync into " .. target)
end

if os_type == "windows" then
	windows_sync()
else
	if not command_exists("nextcloudcmd") then
		c.tag("nextcloud", "nextcloudcmd not installed yet; run bootstrap deps")
		return
	end
	unix_sync()
end
