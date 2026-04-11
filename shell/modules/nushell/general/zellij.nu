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
