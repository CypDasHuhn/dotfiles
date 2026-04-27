# Ensure XDG_RUNTIME_DIR exists; fall back to /tmp/runtime-<uid> if missing.
# Zellij panics with "Permission denied" if the dir doesn't exist (common on WSL2
# when the systemd user session hasn't started and /run/user/1000 was never created).
def --env ensure-xdg-runtime [] {
    let os = $nu.os-info.family

    # Windows has no XDG concept; use a per-user temp dir and return early
    if $os == "windows" {
        let dir = ([$env.LOCALAPPDATA, "runtime"] | path join)
        if not ($dir | path exists) { mkdir $dir }
        $env.XDG_RUNTIME_DIR = $dir
        return
    }

    # Unix path
    let dir = ($env | get -o XDG_RUNTIME_DIR | default "")
    if ($dir | is-empty) or not ($dir | path exists) {
        # On WSL2, WSLg's runtime dir already has the wayland-0 socket.
        # Prefer it so nested Wayland compositors (Hyprland) can connect.
        let fallback = if ("/mnt/wslg/runtime-dir" | path exists) {
            "/mnt/wslg/runtime-dir"
        } else {
            $env.XDG_RUNTIME_DIR? | default $"/tmp/runtime-(^id -u | str trim)"
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

def zellij-live-session [] {
    try {
        let sessions = (
            zellij list-sessions --no-formatting
            | lines
            | each {|line|
                let trimmed = ($line | str trim)
                if ($trimmed | is-empty) {
                    null
                } else {
                    $trimmed | split row ' ' | get 0
                }
            }
            | compact
        )

        if ($sessions | is-empty) {
            null
        } else {
            $sessions | get 0
        }
    } catch {
        null
    }
}

def zellij-resurrectable-session [] {
    let session_info_dir = ($nu.home-path | path join ".cache" "zellij" "contract_version_1" "session_info")
    if not ($session_info_dir | path exists) {
        return null
    }

    let candidates = (
        ls $session_info_dir
        | where type == dir
        | each {|dir|
            let metadata = ($dir.name | path join "session-metadata.kdl")
            if ($metadata | path exists) {
                {
                    session: ($dir.name | path basename)
                    modified: (ls $metadata | get modified | first)
                }
            }
        }
        | compact
        | sort-by modified --reverse
    )

    if ($candidates | is-empty) {
        null
    } else {
        $candidates | get session | first
    }
}

def zj [] {
    let live_session = (zellij-live-session)
    if $live_session != null {
        zellij attach --create --force-run-commands $live_session
        return
    }

    let resurrectable_session = (zellij-resurrectable-session)
    if $resurrectable_session != null {
        zellij attach --create --force-run-commands $resurrectable_session
    } else {
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

# Run a command inside `nu -c` and replace it with an interactive shell when it exits.
# Use this for commands you intend to resurrect in Zellij, otherwise the pane will be
# restored as a one-shot command pane and hang after the command finishes.
def zjcmd [command: string] {
    ^nu -c $'do { ($command) }; exec nu'
}

# Open a new Zellij pane that runs a command and then drops back into `nu` in the
# same working directory once the command exits.
def zjp [
    command: string,
    --direction (-d): string,
    --floating (-f),
    --in-place (-i),
    --name (-n): string,
] {
    mut args = ["action" "new-pane" "--cwd" $env.PWD]

    if $direction != null {
        $args = ($args | append ["--direction" $direction])
    }
    if $floating {
        $args = ($args | append "--floating")
    }
    if $in_place {
        $args = ($args | append "--in-place")
    }
    if $name != null {
        $args = ($args | append ["--name" $name])
    }

    ^zellij ...$args -- "nu" "-c" $'do { ($command) }; exec nu'
}
