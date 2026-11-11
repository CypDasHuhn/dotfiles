local vars = {
	enerko = { "/i2s.EES.RedispatchPortal" },
	retrakt = { "/i2s.Retrakt.DPP" },
	usp = { "/BDEW_Umsatzportal" },
	otis = { "/i2s.Bayer.OTIS" },
	sgProj = { "/i2s.SecGate.CentralUpdater" },
}

local worktree_vars = {}

for project, v in pairs(vars) do
	local project_path = v[1]
	v.dir_function = true
	v[1] = "${repos}" .. project_path
	worktree_vars[project .. "Worktrees"] = {
		"${worktrees}" .. project_path,
		dir_function = true,
	}
end

for project, v in pairs(worktree_vars) do
	vars[project] = v
end

return vars
