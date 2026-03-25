-- Helper functions for common dependency patterns
local M = {}

-- Builder metatable — chainable methods on any dependency declaration
local dep_mt = {}
dep_mt.__index = dep_mt

local function apply_to_leaves(t, field, value)
	if type(t) ~= "table" then return end
	if t.command ~= nil then
		t[field] = value
		return
	end
	for k, v in pairs(t) do
		if type(v) == "string" then
			t[k] = { command = v, [field] = value }
		elseif type(v) == "table" then
			apply_to_leaves(v, field, value)
		end
	end
end

function dep_mt:condition(c)
	apply_to_leaves(self, "condition", c)
	return self
end

function dep_mt:verify(v)
	apply_to_leaves(self, "verify", v)
	return self
end

function dep_mt:once()
	apply_to_leaves(self, "once", true)
	return self
end

function M.dep(t)
	return setmetatable(t, dep_mt)
end

-- Condition helpers
function M.which(name)
	return "command -v " .. name .. " >/dev/null 2>&1"
end

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

-- Package manager commands
-- binary is optional - will try both pkg name and binary name
function M.pacman(name, binary)
	return M.dep({
		command = "sudo pacman -S --noconfirm --needed " .. name,
		verify = M.which_any(build_binary_list(name, binary)),
	})
end

function M.yay(name, binary)
	return M.dep({
		command = "yay -S --noconfirm --needed " .. name,
		verify = M.which_any(build_binary_list(name, binary)),
	})
end

function M.winget(name, binary)
	return M.dep({
		command = "winget install --silent --accept-package-agreements --accept-source-agreements " .. name,
		verify = binary and M.which(binary) or nil,
		once = true,
	})
end

-- Cross-platform helpers
function M.vanilla(arch_name, winget_name, binary)
	return M.dep({
		unix = {
			arch = M.pacman(arch_name, binary or arch_name),
		},
		windows = {
			default = M.winget(winget_name, binary or arch_name),
		},
	})
end

function M.chocolate(aur_name, winget_name, binary)
	return M.dep({
		unix = {
			arch = M.yay(aur_name, binary or aur_name),
		},
		windows = {
			default = M.winget(winget_name, binary or aur_name),
		},
	})
end

-- Tool helpers (condition = tool must exist, once = skip if already installed)
function M.npm_pkg(name, binary)
	return M.dep({
		command = "npm install -g " .. name,
		condition = M.which("npm"),
		verify = M.which_any(build_binary_list(name, binary)),
		once = true,
	})
end

function M.pipx_pkg(name, binary)
	return M.dep({
		command = "pipx install " .. name,
		condition = M.which("pipx"),
		verify = M.which_any(build_binary_list(name, binary)),
		once = true,
	})
end

function M.cargo_pkg(name, binary)
	return M.dep({
		command = "cargo install " .. name,
		condition = M.which("cargo"),
		verify = M.which_any(build_binary_list(name, binary)),
		once = true,
	})
end

-- binary is required since go packages are like "github.com/foo/bar@latest"
function M.go_pkg(name, binary)
	return M.dep({
		command = "go install " .. name,
		condition = M.which("go"),
		verify = binary and M.which(binary) or nil,
		once = true,
	})
end

return M
