def rdp_completions [] {
    ls $env.rdp
    | where type == file
    | where name =~ '\.rdp$'
    | each { |file| $file.name | path basename | str replace -r '\.rdp$' '' }
}

def rdp [name?: string@rdp_completions] {
    if ($name == null) {
        return (ls $env.rdp)
    }

    let match = (ls $env.rdp | where ($it.name | path basename) == $"($name).rdp")
    
    if ($match | is-empty) {
        error make { msg: "File not found" }
    }

    # Start the rdp file with mstsc defaullt association in cmd. The cmd doesnt block the chain unlike nushell.
    cmd /c start "" $match.name.0
}
