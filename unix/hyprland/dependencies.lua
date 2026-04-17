local h = require("infra.dependencies.helpers")

return {
    -- Hyprland is in the official Arch repos (extra)
    hyprland = h.pacman("hyprland", "Hyprland"):once(),

    kitty = h.pacman("kitty"):once(),

    -- Wayland support libraries for Qt/GTK apps
    ["qt5-wayland"] = h.dep({
        command = "sudo pacman -S --noconfirm --needed qt5-wayland",
    }):once(),
    ["qt6-wayland"] = h.dep({
        command = "sudo pacman -S --noconfirm --needed qt6-wayland",
    }):once(),

    -- Portal backend for Hyprland (screen sharing, file pickers, etc.)
    ["xdg-desktop-portal-hyprland"] = h.pacman("xdg-desktop-portal-hyprland"):once(),
}
