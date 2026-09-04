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

    tmux-ensure-plugins

    let server = (do -i { ^tmux has-session } | complete)
    if $server.exit_code == 0 {
        ^tmux attach-session
        return
    }

    ^tmux new-session -d -s __tmux_restore__
    sleep 1500ms
    ^tmux attach-session
}

def tmux-config-file [] {
    let xdg = ($env.XDG_CONFIG_HOME? | default ($nu.home-dir | path join ".config"))
    $xdg | path join "tmux" "tmux.conf"
}

def tmux-plugins-root [] {
    tmux-config-file | path dirname | path join "plugins"
}

# Parse `set -g @plugin 'owner/repo'` entries from the config text the same way
# TPM does: tmux keeps only the last value of a repeated user option, so the
# running server can't report the full list and TPM reads the file instead.
def tmux-declared-plugins [] {
    let conf = (tmux-config-file | path dirname | path join "options.conf")
    if not ($conf | path exists) {
        return []
    }

    open --raw $conf
    | lines
    | where {|l| ($l | str trim | str starts-with "set") and ($l | str contains "@plugin") }
    | each {|l|
        $l
        | str replace --all "'" ""
        | str replace --all '"' ""
        | str trim
        | split row ' '
        | last
        | str trim
    }
}

# Bootstrap TPM (it can't clone itself) and install any plugins that are still
# missing. No-ops quickly once everything is present.
def tmux-ensure-plugins [] {
    let root = (tmux-plugins-root)
    let tpm = ($root | path join "tpm" "tpm")

    if not ($tpm | path exists) {
        if not ($root | path exists) { mkdir $root }
        ^git clone --quiet https://github.com/tmux-plugins/tpm ($root | path join "tpm")
    }

    let missing = (
        tmux-declared-plugins
        | each {|p| $p | str replace --regex '\.git$' '' | path basename }
        | each {|name| $root | path join $name }
        | where {|dir| not ($dir | path exists) }
    )

    if ($missing | is-empty) {
        return
    }

    # TPM's installer reads the @plugin list and its install target from a
    # running server. Bring one up and point TMUX_PLUGIN_MANAGER_PATH at the
    # plugins dir; a server that started before tpm existed won't have it set.
    ^tmux start-server
    ^tmux set-environment -g TMUX_PLUGIN_MANAGER_PATH $root
    ^bash ($root | path join "tpm" "bin" "install_plugins")

    # Reload so the running server sources the plugins we just installed.
    ^tmux source-file (tmux-config-file)
}
