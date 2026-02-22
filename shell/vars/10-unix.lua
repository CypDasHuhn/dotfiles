local vars = {
	konsoleConfig = {
		"${dotfiles}/terminal-emulator/konsole/generated.rc",
		only = "unix",
	},
	systemKonsole = {
		"${me}/.local/share/kxmlgui5/konsole/konsoleui.rc",
		only = "unix",
	},
	kittyConfig = {
		"${dotfiles}/terminal-emulator/kitty/generated.conf",
		only = "unix",
	},
	systemKitty = {
		"${me}/.config/kitty/kitty.conf",
		only = "unix",
	},
	hyprland = {
		"${dotfiles}/hyprland",
		only = "unix",
	},
	systemHyprland = {
		"${me}/.config/hypr",
		only = "unix",
	},
}

for _, v in pairs(vars) do
	v.only = { "unix" }
end

return vars
