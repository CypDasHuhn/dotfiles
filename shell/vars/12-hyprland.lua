local vars = {
	hyprlandDotfiles = { "${dotfiles}/unix/hyprland" },
	systemHyprland = { "${me}/.config/hypr" },
	hyprpanelDotfiles = { "${dotfiles}/unix/hyprland/hyprpanel" },
	systemHyprpanel = { "${me}/.config/hyprpanel" },
}

for _, v in pairs(vars) do
	v.only = { visual = "hyprland" }
end

return vars
