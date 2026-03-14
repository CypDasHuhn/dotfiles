-- Helper functions for common dependency patterns
local M = {}

-- Condition helpers
-- Single name check
function M.which(name)
	return "command -v " .. name .. " >/dev/null 2>&1"
end

-- Multiple names - passes if any exist
function M.which_any(names)
	if type(names) == "string" then
		return M.which(names)
	end
	local checks = {}
	for _, name in ipairs(names) do
		table.insert(checks, "command -v " .. name .. " >/dev/null 2>&1")
	end
	return table.concat(checks, " || ")
end

function M.file_exists(path)
	return "[ -f " .. path .. " ]"
end

function M.dir_exists(path)
	return "[ -d " .. path .. " ]"
end

-- Build list of binary names to try (package name + optional extra)
local function build_binary_list(pkg_name, extra_binary)
	local names = { pkg_name }
	if extra_binary and extra_binary ~= pkg_name then
		table.insert(names, extra_binary)
	end
	return names
end

-- Package manager commands (no prompts, skip if up-to-date)
-- Returns { command = "...", verify = "..." }
-- binary is optional - will try both pkg name and binary name
function M.pacman(name, binary)
	return {
		command = "sudo pacman -S --noconfirm --needed " .. name,
		verify = M.which_any(build_binary_list(name, binary)),
	}
end

function M.yay(name, binary)
	return {
		command = "yay -S --noconfirm --needed " .. name,
		verify = M.which_any(build_binary_list(name, binary)),
	}
end

function M.winget(name, binary)
	return {
		command = "winget install --silent --accept-package-agreements --accept-source-agreements "
			.. name
			.. " || winget upgrade --silent --accept-package-agreements --accept-source-agreements "
			.. name,
		-- winget names aren't binaries, so only use explicit binary if provided
		verify = binary and M.which(binary) or nil,
	}
end

function M.apt(name, binary)
	return {
		command = "sudo apt install -y " .. name,
		verify = M.which_any(build_binary_list(name, binary)),
	}
end

-- Vanilla package: same name across package managers (pacman)
-- binary is optional - verify tries both pkg name and binary
function M.vanilla(arch_name, winget_name, binary)
	return {
		unix = {
			arch = M.pacman(arch_name, binary or arch_name),
		},
		windows = {
			default = M.winget(winget_name, binary or arch_name),
		},
	}
end

-- Chocolate package: same as vanilla but uses yay (AUR)
function M.chocolate(aur_name, winget_name, binary)
	return {
		unix = {
			arch = M.yay(aur_name, binary or aur_name),
		},
		windows = {
			default = M.winget(winget_name, binary or aur_name),
		},
	}
end

-- NPM global package (tool helper with condition + verify)
-- binary optional - tries both pkg name and binary
function M.npm_pkg(name, binary)
	return {
		command = "npm install -g " .. name,
		condition = M.which("npm"),
		verify = M.which_any(build_binary_list(name, binary)),
	}
end

-- Pipx package (tool helper with condition + verify)
function M.pipx_pkg(name, binary)
	return {
		command = "pipx install " .. name,
		condition = M.which("pipx"),
		verify = M.which_any(build_binary_list(name, binary)),
	}
end

-- Cargo package (tool helper with condition + verify)
function M.cargo_pkg(name, binary)
	return {
		command = "cargo install " .. name,
		condition = M.which("cargo"),
		verify = M.which_any(build_binary_list(name, binary)),
	}
end

-- Go package (tool helper with condition + verify)
-- binary is required since go packages are like "github.com/foo/bar@latest"
function M.go_pkg(name, binary)
	return {
		command = "go install " .. name,
		condition = M.which("go"),
		verify = binary and M.which(binary) or nil,
	}
end

return M
