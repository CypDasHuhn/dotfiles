local vars = {
	kittyConfig = { "${dotfiles}/terminal-emulator/kitty/generated.conf" },
	systemKitty = { "${me}/.config/kitty/kitty.conf" },
	konsoleConfig = { "${dotfiles}/terminal-emulator/konsole/generated.rc" },
	systemKonsole = { "${me}/.local/share/kxmlgui5/konsole/konsoleui.rc" },
}

for _, v in pairs(vars) do
	v.only = { "unix" }
end

return vars
