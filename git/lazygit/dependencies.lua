local h = require("infra.dependencies.helpers")

local has_setuptools = "python -c 'import setuptools'"
local has_psutil = "python -c 'import psutil'"

return {
	["python-setuptools"] = h.dep({
			unix = h.pacman("python-setuptools"),
		})
		:verify(has_setuptools)
		:once(),

	["python-psutil"] = h.dep({
			unix = h.pacman("python-psutil"),
		})
		:verify(has_psutil)
		:once(),

	lazygit = h.dep({
			unix = h.pacman("lazygit"),
		})
		:verify(h.which("lazygit"))
		:once(),

	nvr = h.dep({
			unix = h.yay("neovim-remote", "nvr"),
		})
		:condition(h.which("nvim") .. " && " .. has_setuptools)
		:verify("nvr --help")
		:once(),
}
