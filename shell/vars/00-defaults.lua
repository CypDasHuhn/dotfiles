return {
	me = {
		unix = "$HOME",
		windows = "C:\\Users\\c.lenoir",
	},

	repos = {
		"${me}/repos",
		dir_function = true,
		machines = {
			["work-laptop"] = "${me}/source/repos",
			["work-rdp"] = "D:\\Repos",
		},
	},

	dotfiles = {
		"${me}/dotfiles",
		dir_function = true,
	},

	appdata = { "${me}/AppData", only = "windows" },
	appdataLocal = { "${appdata}/Local", only = "windows" },
	appdataRoaming = { "${appdata}/Roaming", only = "windows" },

	nvim = {
		"${dotfiles}/nvim",
	},
	systemNvim = {
		unix = "${me}/.config/nvim",
		windows = "${appdataLocal}/nvim",
	},

	wezterm = {
		path = "${me}/.wezterm.lua",
	},
	vault = {
		path = "${me}/Documents/CypVault",
		dir_function = true,
	},
	shellConfig = {
		"${dotfiles}/shell",
		dir_function = true,
	},
}
