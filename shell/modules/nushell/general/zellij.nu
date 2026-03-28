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
