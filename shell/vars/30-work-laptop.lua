local vars = {
	rdp = { "${me}/Desktop/rdp" },
}

for _, v in pairs(vars) do
	v.only = "work-laptop"
end

return vars
