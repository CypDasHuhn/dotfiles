local vars = {
	enerko = {
		path = "${repos}/i2s.EES.RedispatchPortal",
		dir_function = true,
	},

	usp = {
		path = "${repos}/BDEW_Umsatzportal",
		dir_function = true,
	},

	otis = {
		path = "${repos}/i2s.Bayer.OTIS",
		dir_function = true,
	},

	ihkDoku = {
		path = "${repos}/ihk-projekt-doku",
		dir_function = true,
	},
}

for _, v in pairs(vars) do
	v.only = { "work-rdp" }
end

return vars
