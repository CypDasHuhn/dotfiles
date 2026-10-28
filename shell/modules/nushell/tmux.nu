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

    let server = (do -i { ^tmux list-sessions } | complete)
    if $server.exit_code == 0 {
        ^tmux attach-session
        return
    }

    ^tmux
}

def --wrapped tmux-workspace [...args] {
    let script = (tmux-config-file | path dirname | path join "scripts" "workspace.nu")
    tmux-ensure-plugins
    let action = if (($args | get -o 0 | default "") == "repin") { "repin" } else { "open" }
    let command_args = if $action == "repin" { $args | skip 1 } else { $args }
    ^nu --no-config-file $script $action ...$command_args
}

alias tws = tmux-workspace

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
