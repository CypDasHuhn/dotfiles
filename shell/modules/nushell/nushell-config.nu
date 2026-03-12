# nushell-specific configuration

$env.EDITOR = "nvim"

$env.config.keybindings ++= [
    {
        name: accept_autosuggestion
        modifier: control
        keycode: char_y
        mode: [emacs, vi_normal, vi_insert]
        event: { send: HistoryHintComplete }
    }
]
