local function run(opts)
	local generated_dir = opts.generated_dir
	local machine_name = opts.machine_name or ""
	local helpers = opts.helpers or {}
	local list_files_recursive = helpers.list_files_recursive
	local get_relative_path = helpers.get_relative_path
	local write_file = helpers.write_file

	if not generated_dir or not list_files_recursive or not get_relative_path or not write_file then
		error("home: missing required context")
	end

	local output_file = generated_dir .. "\\home.ahk"
	local output_file_lower = output_file:lower()

	local input_files = {}
	for _, file in ipairs(list_files_recursive(generated_dir, "*.ahk")) do
		if file:lower() ~= output_file_lower then
			table.insert(input_files, file)
		end
	end

	table.sort(input_files, function(a, b)
		return a:lower() < b:lower()
	end)

	local lines = {
		"; Auto-generated file - DO NOT EDIT MANUALLY",
		"; Generated: " .. os.date("%Y-%m-%d %H:%M:%S"),
		"; Machine: " .. machine_name,
		"",
		"#Requires AutoHotkey v2.0",
		"#SingleInstance Force",
		"",
	}

	for _, file in ipairs(input_files) do
		local relative = get_relative_path(generated_dir, file)
		table.insert(lines, '#Include "' .. relative .. '"')
	end

	local content = table.concat(lines, "\n")
	local ok, err = write_file(output_file, content)
	if not ok then
		error("home: failed to write " .. output_file .. ": " .. (err or "unknown"))
	end
end

return { run = run }
