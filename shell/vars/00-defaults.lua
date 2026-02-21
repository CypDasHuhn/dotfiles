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

	nvim = {
		"${dotfiles}/nvim",
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
