local function get_script_dir()
	local source = debug.getinfo(1, "S").source:gsub("^@", "")
	local path = source:match("(.+[\\/])")
	if not path then
		return "."
	end
	path = path:gsub("\\", "/"):gsub("/$", "")
	if path:sub(1, 1) == "/" then
		return path
	end

	local handle = io.popen("pwd")
	local cwd = handle and handle:read("*l") or "."
	if handle then
		handle:close()
	end
	return (cwd:gsub("/$", "") .. "/" .. path):gsub("/%./", "/")
end

local services_dir = get_script_dir()
local dotfiles_dir = services_dir:gsub("/unix/services$", "")

package.path = dotfiles_dir .. "/infra/?.lua;" .. services_dir .. "/?.lua;" .. package.path

local c = require("colors")
local generator = require("generator")

local ok, generated_dir_or_err, services = generator.generate()
if not ok then
	c.tag_err("services", generated_dir_or_err)
	return
end

local home = os.getenv("HOME")
if not home or home == "" then
	c.tag_err("services", "HOME is not set")
	return
end

local user_units_dir = home .. "/.config/systemd/user"
os.execute('mkdir -p "' .. user_units_dir .. '"')

for _, service in ipairs(services) do
	local unit = "dotfiles-" .. service.name .. ".service"
	local source = generated_dir_or_err .. "/" .. unit
	local target = user_units_dir .. "/" .. unit
	local current = nil
	local handle = io.popen('readlink "' .. target .. '" 2>/dev/null')
	if handle then
		current = handle:read("*l")
		handle:close()
	end

	if current == source then
		c.dim("[services] already linked: " .. unit)
	else
		local exists = os.execute('test -e "' .. target .. '"')
		local is_link = os.execute('test -L "' .. target .. '"')
		if exists == true or exists == 0 or is_link == true or is_link == 0 then
			if is_link == true or is_link == 0 then
				os.execute('rm -f "' .. target .. '"')
			else
				c.tag_warn("services", "skipping existing real unit: " .. target)
				goto continue
			end
		end

		local result = os.execute('ln -s "' .. source .. '" "' .. target .. '"')
		if result == true or result == 0 then
			c.tag_ok("services", "linked: " .. unit)
		else
			c.tag_err("services", "failed to link: " .. unit)
		end
	end

	::continue::
end
