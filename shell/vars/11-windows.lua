local vars = {
	appdata = { "${me}/AppData" },
	appdataLocal = { "${appdata}/Local" },
	appdataRoaming = { "${appdata}/Roaming" },
	ahk = { "${dotfiles}/ahk" },
	psProfile = { "${shellConfig}/generated/profile.ps1" },
	startup = { "${appdataRoaming}/Microsoft/Windows/Start Menu/Programs/Startup" },
	windowsTerminal = { "${appdataLocal}/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState" },
	windowsTerminalSettings = { "${windowsTerminal}/settings.json" },
}

for _, v in pairs(vars) do
	v.only = { "windows" }
end

return vars
