# With no arguments, resume tmux instead of creating a new session. On a cold
# server, invoking tmux directly lets Continuum restore into its normal
# temporary startup session, which Resurrect removes when appropriate.
def --wrapped tmux [...args] {
    if not ($args | is-empty) {
        ^tmux ...$args
        return
    }

    if "TMUX" in $env {
        ^tmux
        return
    }

    tmux-ensure-plugins

    # Older versions of this wrapper created __tmux_restore__ as a bootstrap
    # session. Remove it so it cannot be kept alive or saved again.
    let restore = (do -i { ^tmux has-session -t "=__tmux_restore__" } | complete)
    if $restore.exit_code == 0 {
        ^tmux kill-session -t "=__tmux_restore__"
    }

    # Use the exit status rather than parsing output: psmux has returned an
    # empty list for list-sessions in some versions.
    let server = (do -i { ^tmux list-sessions } | complete)
    if $server.exit_code == 0 {
        ^tmux attach-session
        return
    }

    ^tmux
}

def tmux-config-file [] {
    let xdg = ($env.XDG_CONFIG_HOME? | default ($nu.home-dir | path join ".config"))
    $xdg | path join "tmux" "tmux.conf"
}

# Install missing plugins before a cold server starts, so Continuum is loaded
# in time for its server-start restore.
def tmux-ensure-plugins [] {
    let script = (tmux-config-file | path dirname | path join "scripts" "ensure-plugins.sh")
    if not ($script | path exists) {
        return
    }

    ^bash $script
}
