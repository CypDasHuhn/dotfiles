def parse-token [tok: string] {
    if ($tok =~ '^\d{1,2}:\d{2}$') {
        let parts = ($tok | split row ':')
        {type: "time", val: (($parts.0 | into int) * 60 + ($parts.1 | into int))}
    } else if ($tok =~ '^\d+h\d+m$') {
        let h = ($tok | parse '{h}h{m}m' | get 0)
        {type: "dur", val: (($h.h | into int) * 60 + ($h.m | into int))}
    } else if ($tok =~ '^\d+h$') {
        {type: "dur", val: (($tok | str replace 'h' '' | into int) * 60)}
    } else if ($tok =~ '^\d+m$') {
        {type: "dur", val: ($tok | str replace 'm' '' | into int)}
    } else {
        error make {msg: $"bad token: ($tok)"}
    }
}

def timecalc [...tokens: string] {
    mut acc = (parse-token $tokens.0)
    mut i = 1
    while $i < ($tokens | length) {
        let op = ($tokens | get $i)
        let rhs = (parse-token ($tokens | get ($i + 1)))
        $acc = (match [$acc.type, $rhs.type, $op] {
            ["time", "dur", "+"] => {type: "time", val: (($acc.val + $rhs.val) mod 1440)}
            ["time", "dur", "-"] => {type: "time", val: ((($acc.val - $rhs.val) mod 1440 + 1440) mod 1440)}
            ["time", "time", "-"] => {type: "dur", val: ($acc.val - $rhs.val)}
            ["time", "time", "to"] => {type: "dur", val: ($rhs.val - $acc.val)}
            ["dur", "dur", "+"] => {type: "dur", val: ($acc.val + $rhs.val)}
            ["dur", "dur", "-"] => {type: "dur", val: ($acc.val - $rhs.val)}
            _ => (error make {msg: $"invalid: ($acc.type) ($op) ($rhs.type)"})
        })
        $i = $i + 2
    }
    if $acc.type == "time" {
        $"($acc.val // 60 | fill -a right -c '0' -w 2):($acc.val mod 60 | fill -a right -c '0' -w 2)"
    } else {
        let sign = if $acc.val < 0 { "-" } else { "" }
        let av = ($acc.val | math abs)
        $"($sign)($av // 60)h($av mod 60)m"
    }
}

alias tc = timecalc

def t-sleep [--duration: string = "7h30m", ...tokens: string] {
    let fullTokens = ($tokens | append "-" | append $duration)
    timecalc ...$fullTokens
}

def t-work [--slack: string = "30m", ...tokens: string] {
    let fullTokens = ($tokens | append "-" | append $slack)
    timecalc ...$fullTokens
}
