local vars = {
	appdata = { "${me}/AppData" },
	appdataLocal = { "${appdata}/Local" },
	appdataRoaming = { "${appdata}/Roaming" },
	programFiles = { "C:/Program Files" },

	ahk = { "${dotfiles}/ahk" },
	ahkKeys = { "${ahk}/generated/config.ini" },
	psProfile = { "${shellConfig}/generated/profile.ps1" },
	systemPsProfile = { "C:/Program Files/PowerShell/7/profile.ps1" },

	startup = { "${appdataRoaming}/Microsoft/Windows/Start Menu/Programs/Startup" },

	windowsTerminalConfig = {
		"${dotfiles}/terminal/emulator/windows-terminal/generated.json",
	},
	systemWindowsTerminal = {
		"${appdataLocal}/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json",
	},
}

for _, v in pairs(vars) do
	v.only = { os = "windows" }
end

return vars
