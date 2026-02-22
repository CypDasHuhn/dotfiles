local vars = {
	hyprland = { "${dotfiles}/unix/hyprland" },
	systemHyprland = { "${me}/.config/hypr" },
	hyprpanel = { "${dotfiles}/unix/hyprland/hyprpanel" },
	systemHyprpanel = { "${me}/.config/hyprpanel" },
}

for _, v in pairs(vars) do
	v.only = { "hyprland" }
end

return vars
