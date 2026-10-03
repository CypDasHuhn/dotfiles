-- Attach this machine to the Seafile "vault" library.
--
-- Cross-platform:
--   Unix    -> headless `seaf-cli`: init, daemon, download, systemd unit.
--   Windows -> Seafile GUI client, preconfigured through seafile.ini so the
--              login wizard is skipped (library selection stays a GUI step).
--
-- The deployment details are fixed here; the only external value is the
-- account password, read from the gitignored nushell secrets file
-- (shell/modules/nushell/secrets.nu, key SEAFILE_PASSWORD).

local c = require("colors")
local platform = require("platform")

local SERVER = "https://homelab.taila13f78.ts.net"
local LIBRARY = "7853e331-e732-42a0-95e9-abf71e43a1a6"
local ACCOUNT = "Martinfischer533@gmail.com"
local SECRET_KEY = "SEAFILE_PASSWORD"
local TARGET_VAR = "vault"

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

local function process_running(name)
	return ok(os.execute("pgrep -x " .. name .. " >/dev/null 2>&1"))
end

local function command_output(cmd)
	local handle = io.popen(cmd)
	if not handle then
		return nil
	end
	local out = handle:read("*a")
	handle:close()
	return out
end

local dir = script_dir()
local secrets = dir .. "/../../shell/modules/nushell/secrets.nu"

local function read_secret(key)
	if not command_exists("nu") or not file_exists(secrets) then
		return nil
	end
	local script = string.format("open --raw %q | from nuon | get %s", secrets, key)
	local out = command_output("nu --no-config-file -c '" .. script .. "' 2>/dev/null")
	if not out or out == "" then
		return nil
	end
	return (out:gsub("%s+$", ""))
end

local function resolve_target()
	local target = require("linker").resolve(TARGET_VAR)
	if target then
		return target
	end
	local home = os.getenv("HOME") or os.getenv("USERPROFILE") or ""
	return home .. "/vault"
end

local function unix_attach()
	local home = os.getenv("HOME")
	local data_parent = home .. "/.local/share/seafile"
	local ccnet = home .. "/.ccnet"

	if not file_exists(ccnet .. "/seafile.ini") then
		os.execute('mkdir -p "' .. data_parent .. '"')
		c.tag("seafile", "initializing client data dir")
		os.execute('seaf-cli init -d "' .. data_parent .. '"')
	end

	if not process_running("seaf-daemon") then
		c.tag("seafile", "starting seaf-daemon")
		os.execute("seaf-cli start")
	end

	local target = resolve_target()

	local attached = false
	local handle = io.popen("seaf-cli list 2>/dev/null")
	if handle then
		for line in handle:lines() do
			if line:find(LIBRARY, 1, true) then
				attached = true
				break
			end
		end
		handle:close()
	end

	if attached then
		c.tag_ok("seafile", "library attached -> " .. target)
	else
		local password = read_secret(SECRET_KEY)
		if not password then
			c.tag_err("seafile", "missing " .. SECRET_KEY .. " in secrets.nu; cannot attach")
			return
		end
		c.tag("seafile", "attaching library -> " .. target)
		os.execute(string.format(
			"seaf-cli download -l %q -s %q -d %q -u %q -p %q",
			LIBRARY,
			SERVER,
			target,
			ACCOUNT,
			password
		))
	end

	local user = os.getenv("USER")
	if user and user ~= "" then
		local unit = "seaf-cli@" .. user .. ".service"
		if not ok(os.execute("systemctl is-enabled " .. unit .. " >/dev/null 2>&1")) then
			c.tag("seafile", "enabling " .. unit)
			os.execute("sudo systemctl enable --now " .. unit)
		end
	end
end

local function windows_attach()
	if not command_exists("seafile-applet") then
		c.tag("seafile", "Seafile client not installed yet; run bootstrap deps")
		return
	end

	local password = read_secret(SECRET_KEY)
	if not password then
		c.tag_err("seafile", "missing " .. SECRET_KEY .. " in secrets.nu; cannot preconfigure")
		return
	end

	local home = os.getenv("USERPROFILE") or os.getenv("HOME") or ""
	local target = resolve_target()
	local tmp = (os.getenv("TEMP") or home) .. "\\seafile_pw_" .. tostring(os.time()) .. ".txt"

	local handle = io.open(tmp, "w")
	if not handle then
		c.tag_err("seafile", "could not write temporary password file")
		return
	end
	handle:write(password)
	handle:close()

	local ps = dir .. "/preconfigure.ps1"
	local cmd = string.format(
		'powershell -NoProfile -ExecutionPolicy Bypass -File "%s" -Server "%s" -Username "%s" -PasswordFile "%s" -Directory "%s"',
		ps,
		SERVER,
		ACCOUNT,
		tmp,
		target
	)
	local out = command_output(cmd)
	os.remove(tmp)

	if out and out:find("seafile.ini", 1, true) then
		c.tag_ok("seafile", "account preconfigured; launch Seafile and select the 'cyps-vault' library")
	else
		c.tag_err("seafile", "preconfiguration failed")
	end
end

if os_type == "windows" then
	windows_attach()
else
	if not command_exists("seaf-cli") then
		c.tag("seafile", "seaf-cli not installed yet; run bootstrap deps")
		return
	end
	unix_attach()
end
