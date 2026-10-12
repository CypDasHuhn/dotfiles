# Add or update a key in the dotfiles secrets.lua table.
def "secrets add" [
    key: string
    value: string
    --file (-f): path
] {
    if ($key !~ '^[A-Za-z_][A-Za-z0-9_]*$') {
        error make { msg: $"not a valid Lua key: '($key)'" }
    }
    if ($value =~ '[\r\n]') {
        error make { msg: "value must not contain newlines", help: "Lua string literals cannot span lines" }
    }

    let path = if $file == null { $env.dotfiles | path join "secrets.lua" } else { $file }
    let escaped = $value
        | str replace --all '\' '\\'
        | str replace --all '"' '\"'
    let entry = $'    ($key) = "($escaped)",'

    if not ($path | path exists) {
        "return {\n}\n" | save --force $path
    }

    let lines = (open --raw $path | lines)
    let pattern = $'^\s*($key)\s*='
    let existing = ($lines | enumerate | where {|row| $row.item =~ $pattern })

    let updated = if ($existing | is-empty) {
        let closes = ($lines | enumerate | where {|row| ($row.item | str trim) == '}' })
        if ($closes | is-empty) {
            error make { msg: $"could not find the closing '}}' in ($path)" }
        }
        $lines | insert ($closes | last | get index) $entry
    } else {
        $lines | each {|line| if ($line =~ $pattern) { $entry } else { $line } }
    }

    ((($updated | str join "\n") + "\n")) | save --force $path
    print $"set ($key) in ($path)"
}
