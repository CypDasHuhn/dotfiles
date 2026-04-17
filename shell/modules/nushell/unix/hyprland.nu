# Launch Hyprland as a nested Wayland compositor inside WSLg.
# HYPRLAND_BACKEND must be set before the process starts (can't be in hyprland.conf).
def hypr [] {
    with-env {
        HYPRLAND_BACKEND: "wayland",
        WAYLAND_DISPLAY: "wayland-0"
    } {
        Hyprland -c ($env.HOME | path join ".config/hypr/hyprland-wsl.conf")
    }
}

# Launch kitty directly under WSLg (no compositor needed).
# Gives a proper Linux PTY instead of ConPTY.
# Only WAYLAND_DISPLAY needs setting — XDG_RUNTIME_DIR is already /run/user/1000
# from systemd, and the wayland-0 socket lives there too.
def kty [] {
    with-env { WAYLAND_DISPLAY: "wayland-0" } {
        foot
    }
}
