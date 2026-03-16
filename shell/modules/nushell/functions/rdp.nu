def rdp [name: string] {
    if ($name == null) {
        return (ls $env.rdp)
    }

    let match = (ls $env.rdp | where ($it.name | path basename) == $"($name).rdp")
    
    if ($match == null) {
        error make { msg: "File not found" }
    }

    mstsc.exe $match.name.0 
}
