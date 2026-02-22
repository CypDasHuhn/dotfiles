local vars = {
	hyprland = { "${dotfiles}/hyprland" },
	systemHyprland = { "${me}/.config/hypr" },
	hyprpanel = { "${dotfiles}/hyprland/hyprpanel" },
	systemHyprpanel = { "${me}/.config/hyprpanel" },
}

for _, v in pairs(vars) do
	v.only = { "hyprland" }
end

return vars
