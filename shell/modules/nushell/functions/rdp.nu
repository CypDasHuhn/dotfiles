def rdp [name: string] {
    if ($name == null) {
        return (ls $env.rdp)
    }

    let match = (ls $env.rdp | where name == $name)
    
    if ($match == null) {
        error make { msg: "File not found" }
    }
}
