$env.EDITOR = "nvim"
$env.LANG = "en_US.UTF-8"
$env.LC_CTYPE = "en_US.UTF-8"

$env.config.color_config.shape_internalcall = "green_bold"
$env.config.color_config.shape_external = "green"
$env.config.color_config.shape_garbage = "red_bold"

$env.config.edit_mode = "vi"

$env.config.keybindings ++= [
    {
        name: accept_autosuggestion
        modifier: control
        keycode: char_y
        mode: [emacs, vi_normal, vi_insert]
        event: { send: HistoryHintComplete }
    }
    {
        name: menu_left
        modifier: control
        keycode: char_h
        mode: [vi_normal, vi_insert]
        event: { send: menuleft }
    }
    {
        name: menu_down
        modifier: control
        keycode: char_j
        mode: [vi_normal, vi_insert]
        event: { send: menudown }
    }
    {
        name: menu_up
        modifier: control
        keycode: char_k
        mode: [vi_normal, vi_insert]
        event: { send: menuup }
    }
    {
        name: menu_right
        modifier: control
        keycode: char_l
        mode: [vi_normal, vi_insert]
        event: { send: menuright }
    }
]

$env.config.show_banner = false
$env.config.use_kitty_protocol = true

$env.config.shell_integration.osc2 = true   # window title tracks current dir/command
$env.config.shell_integration.osc7 = true   # current dir protocol (foot uses this)

$env.PROMPT_COMMAND = {||
    let user = (whoami | str trim | split row '\\' | last)
    let dir = ($env.PWD | str replace $nu.home-dir "~")
    $"($user):($dir)"
}

alias __sorted_builtin_ls = ls

def ls [
    --all (-a)
    --long (-l)
    --short-names (-s)
    --full-paths (-f)
    --du (-d)
    --directory (-D)
    --mime-type (-m)
    --threads (-t)
    ...pattern: oneof<glob, string>
] {
    let entries = if ($pattern | is-empty) {
        (__sorted_builtin_ls
            --all=$all
            --long=$long
            --short-names=$short_names
            --full-paths=$full_paths
            --du=$du
            --directory=$directory
            --mime-type=$mime_type
            --threads=$threads
        )
    } else {
        (__sorted_builtin_ls
            --all=$all
            --long=$long
            --short-names=$short_names
            --full-paths=$full_paths
            --du=$du
            --directory=$directory
            --mime-type=$mime_type
            --threads=$threads
            ...$pattern
        )
    }

    $entries
    | upsert __directory_order { |entry| $entry.type != "dir" }
    | sort-by __directory_order name
    | reject __directory_order
}
