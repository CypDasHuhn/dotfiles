local vars = {
	vdir = { "/vdir.nvim" },
	learningGamification = { "/LearningGamification" },
	regionLynx = { "/RegionLynx" },
}

for _, v in pairs(vars) do
	v.dir_function = true
	v[1] = "${repos}" .. v[1]
end

return vars
