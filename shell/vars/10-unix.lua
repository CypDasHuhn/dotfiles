local vars = {
	konsoleConfig = {
		"${dotfiles}/terminal-emulator/konsole/generated.rc",
		only = "unix",
	},
	systemKonsole = {
		"${me}/.local/share/kxmlgui5/konsole/konsoleui.rc",
		only = "unix",
	},
}

for _, v in pairs(vars) do
	v.only = { "unix" }
end

return vars
