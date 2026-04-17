# Ensure XDG_RUNTIME_DIR exists; fall back to /tmp/runtime-<uid> if missing.
# Zellij panics with "Permission denied" if the dir doesn't exist (common on WSL2
# when the systemd user session hasn't started and /run/user/1000 was never created).
def --env ensure-xdg-runtime [] {
    let dir = ($env | get -o XDG_RUNTIME_DIR | default "")
    if ($dir | is-empty) or not ($dir | path exists) {
        # On WSL2, WSLg's runtime dir already has the wayland-0 socket.
        # Prefer it so nested Wayland compositors (Hyprland) can connect.
        let fallback = if ("/mnt/wslg/runtime-dir" | path exists) {
            "/mnt/wslg/runtime-dir"
        } else {
            $"/tmp/runtime-(^id -u | str trim)"
        }
        if not ($fallback | path exists) {
            mkdir $fallback
            ^chmod 700 $fallback
        }
        $env.XDG_RUNTIME_DIR = $fallback
    }
}

# Fix XDG_RUNTIME_DIR at shell startup so bare `zellij` invocations also work.
ensure-xdg-runtime

def zj [] {
    try {
        let session = (
            zellij list-sessions --no-formatting
            | lines
            | first
            | str trim
            | split row ' '
            | first
        )
        zellij attach --create --force-run-commands $session
    } catch {
        zellij
    }
}

# Switch or create zellij sessions via fzf (works from inside zellij)
def zjs [] {
    let sessions = (
        zellij list-sessions --no-formatting
        | lines
        | each { |l| $l | str trim | split row ' ' | first }
    )

    let picked = ($sessions | str join "\n" | fzf --prompt "session> ")

    if ($picked | str trim | is-empty) { return }

    # inside a zellij session use the action API, otherwise just attach
    if ($env | get --optional ZELLIJ) != null {
        zellij action switch-session ($picked | str trim)
    } else {
        zellij attach --force-run-commands ($picked | str trim)
    }
}
