local vars = {
	enerko = { "/i2s.EES.RedispatchPortal" },
	usp = { "/BDEW_Umsatzportal" },
	otis = { "/i2s.Bayer.OTIS" },
	sgProj = { "/i2s.SecGate.CentralUpdater" },
}

for _, v in pairs(vars) do
	v.dir_function = true
	v[1] = "${repos}" .. v[1]
end

vars.ihkDoku = { "${vault}/02-work/ihk/projekt/06-Doku", dir_function = true }

return vars
