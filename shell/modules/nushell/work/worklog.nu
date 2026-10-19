def worklog [] {
    help worklog
}

def --wrapped "worklog collect" [...args: string] {
    ^nu --no-config-file ($env.dotfiles | path join misc worklog collect.nu) ...$args
}

def --wrapped "worklog teams" [...args: string] {
    ^nu --no-config-file ($env.dotfiles | path join misc worklog teams.nu) ...$args
}

def --wrapped "worklog prompts" [...args: string] {
    ^nu --no-config-file ($env.dotfiles | path join misc worklog prompts.nu) ...$args
}

def --wrapped "worklog calendar" [...args: string] {
    ^nu --no-config-file ($env.dotfiles | path join misc worklog calendar.nu) ...$args
}

def --wrapped "worklog log" [...args: string] {
    ^nu --no-config-file ($env.dotfiles | path join misc worklog log.nu) ...$args
}

def --wrapped "worklog retrospective" [...args: string] {
    ^nu --no-config-file ($env.dotfiles | path join misc worklog log.nu) --retrospective ...$args
}

def --wrapped "worklog summarize" [...args: string] {
    ^nu --no-config-file ($env.dotfiles | path join misc worklog summarize.nu) ...$args
}

def --wrapped "worklog cleanup" [...args: string] {
    ^nu --no-config-file ($env.dotfiles | path join misc worklog cleanup.nu) ...$args
}
