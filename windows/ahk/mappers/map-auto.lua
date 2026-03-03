local function trim(value)
	return (value or ""):match("^%s*(.-)%s*$")
end

local function split_machine_names(value)
	local names = {}
	if not value or value == "" then
		return names
	end
	for entry in value:gmatch("[^,;]+") do
		local trimmed = trim(entry)
		if trimmed ~= "" then
			table.insert(names, trimmed)
		end
	end
	return names
end

local function get_filter_value(header, key)
	local text = (header or ""):lower()
	local needle = key:lower()
	local value = text:match(needle .. "%s*=%s*\"([^\"]+)\"")
	if not value then
		value = text:match(needle .. "%s*=%s*'([^']+)'")
	end
	if not value then
		value = text:match(needle .. "%s*=%s*([^%s]+)")
	end
	return value
end

local function name_matches(machine_name, value)
	if not machine_name or machine_name == "" then
		return false
	end
	local machine = machine_name:lower()
	for _, candidate in ipairs(split_machine_names(value)) do
		if candidate:lower() == machine then
			return true
		end
	end
	return false
end

local function should_include_block(header, machine_name)
	local only = get_filter_value(header, "only")
	if only and only ~= "" and not name_matches(machine_name, only) then
		return false
	end
	local exclude = get_filter_value(header, "exclude")
	if exclude and exclude ~= "" and name_matches(machine_name, exclude) then
		return false
	end
	return true
end

local function transform_auto_blocks(text, machine_name)
	if not text or text == "" then
		return text
	end
	if not text:lower():find("#auto", 1, true) then
		return text
	end

	local out = {}
	local idx = 1
	while true do
		local start_pos, end_pos, header = text:find("[ \t]*;?[ \t]*#AUTO([^\r\n]*)\r?\n", idx)
		if not start_pos then
			table.insert(out, text:sub(idx))
			break
		end

		table.insert(out, text:sub(idx, start_pos - 1))
		local body_start = end_pos + 1
		local body_end_start, body_end_end = text:find("[ \t]*;?[ \t]*#ENDAUTO[^\r\n]*\r?\n?", body_start)
		if not body_end_start then
			table.insert(out, text:sub(start_pos))
			break
		end

		local body = text:sub(body_start, body_end_start - 1)
		if should_include_block(header or "", machine_name) then
			table.insert(out, body)
		end
		idx = body_end_end + 1
	end

	return table.concat(out)
end

local function run(opts)
	local generated_dir = opts.generated_dir
	local machine_name = opts.machine_name or ""
	local helpers = opts.helpers or {}
	local list_files_recursive = helpers.list_files_recursive
	local read_file = helpers.read_file
	local write_file = helpers.write_file

	if not generated_dir or not list_files_recursive or not read_file or not write_file then
		error("map-auto: missing required context")
	end

	local files = list_files_recursive(generated_dir, "*.ahk")
	for _, file in ipairs(files) do
		local original = read_file(file)
		if original then
			local updated = transform_auto_blocks(original, machine_name)
			if updated ~= original then
				local ok, err = write_file(file, updated)
				if not ok then
					error("map-auto: failed to write " .. file .. ": " .. (err or "unknown"))
				end
			end
		end
	end
end

return { run = run }
