$env.EDITOR = "nvim"

$env.config.color_config.shape_internalcall = "green_bold"
$env.config.color_config.shape_external = "green"
$env.config.color_config.shape_garbage = "red_bold"

$env.config.keybindings ++= [
    {
        name: accept_autosuggestion
        modifier: control
        keycode: char_y
        mode: [emacs, vi_normal, vi_insert]
        event: { send: HistoryHintComplete }
    }
]
