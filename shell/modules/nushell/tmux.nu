# With no arguments, resume tmux instead of creating a new session. A cold
# server needs a detached bootstrap session so Continuum can restore saved ones.
def --wrapped tmux [...args] {
    if not ($args | is-empty) {
        ^tmux ...$args
        return
    }

    if "TMUX" in $env {
        ^tmux
        return
    }

    let server = (do -i { ^tmux has-session } | complete)
    if $server.exit_code == 0 {
        ^tmux attach-session
        return
    }

    ^tmux new-session -d -s __tmux_restore__
    sleep 1500ms
    ^tmux attach-session
}
