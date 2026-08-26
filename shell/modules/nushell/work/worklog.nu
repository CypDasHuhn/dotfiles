def worklog [] {
    help worklog
}

def --wrapped "worklog collect" [...args: string] {
    ^nu --no-config-file ($env.dotfiles | path join misc worklog collect.nu) ...$args
}

def --wrapped "worklog summarize" [...args: string] {
    ^nu --no-config-file ($env.dotfiles | path join misc worklog summarize.nu) ...$args
}

def --wrapped "worklog cleanup" [...args: string] {
    ^nu --no-config-file ($env.dotfiles | path join misc worklog cleanup.nu) ...$args
}
