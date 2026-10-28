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
    let closes = ($lines | enumerate | where {|row| ($row.item | str trim) == '}' })
    if ($closes | is-empty) {
        error make { msg: $"could not find the closing '}}' in ($path)" }
    }
    let closing_index = ($closes | last | get index)
    let entries = ($lines | enumerate | where {|row|
        $row.index < $closing_index and not (($row.item | str trim) | is-empty)
    })
    let normalized = if ($entries | is-empty) {
        $lines
    } else {
        let last_entry = ($entries | last)
        let trimmed = ($last_entry.item | str trim)
        if ($trimmed =~ '^[A-Za-z_][A-Za-z0-9_]*\s*=' and not ($trimmed | str ends-with ',')) {
            $lines | update $last_entry.index ($last_entry.item + ',')
        } else {
            $lines
        }
    }
    let pattern = $'^\s*($key)\s*='
    let existing = ($normalized | enumerate | where {|row| $row.item =~ $pattern })

    let updated = if ($existing | is-empty) {
        $normalized | insert $closing_index $entry
    } else {
        $normalized | each {|line| if ($line =~ $pattern) { $entry } else { $line } }
    }

    ((($updated | str join "\n") + "\n")) | save --force $path
    print $"set ($key) in ($path)"
}
