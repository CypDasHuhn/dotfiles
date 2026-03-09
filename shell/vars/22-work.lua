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

local projekt = "${vault}/02-work/ihk/projekt/"
local projektDirs = {
	lastenheft = "02-Planung/Lastenheft",
	pflichtenheft = "03-Entwurf/Pflichtenheft",
	ihkDoku = "06-Doku",
}
for k, v in pairs(projektDirs) do
	vars[k] = { projekt .. v, dir_function = true }
end

return vars
