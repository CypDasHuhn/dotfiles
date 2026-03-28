local vars = {
	zen = { "${dotfiles}/browser/zen" },
	kittyConfig = { "${dotfiles}/terminal/emulator/kitty/generated.conf" },
	systemKitty = { "${me}/.config/kitty/kitty.conf" },
	konsoleConfig = { "${dotfiles}/terminal/emulator/konsole/generated.rc" },
	systemKonsole = { "${me}/.local/share/kxmlgui5/konsole/konsoleui.rc" },
	weztermConfig = { "${dotfiles}/terminal/emulator/wezterm/generated.lua" },
	systemWezterm = { "${me}/.config/wezterm/wezterm.lua" },
	tmux = { "${dotfiles}/terminal/multiplexer/tmux" },
	systemTmux = { "${me}/.config/tmux" },
	zellij = { "${dotfiles}/terminal/multiplexer/zellij" },
	systemZellij = { "${me}/.config/zellij" },
}

for _, v in pairs(vars) do
	v.only = { os = "unix" }
end

return vars
