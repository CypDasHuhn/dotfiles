$env.sleepDuration = "7h30m"
$env.wakeUpTime = "06:00"

def next-boundary [step: int] {
    let h = (date now | format date '%H' | into int)
    let m = (date now | format date '%M' | into int)
    let wrapped = ((((($h * 60) + $m) // $step) + 1) * $step mod 1440)
    $"($wrapped // 60 | fill -a right -c '0' -w 2):($wrapped mod 60 | fill -a right -c '0' -w 2)"
}

let fill_ins = {
    now: {|| date now | format date '%H:%M'}
    q: {|| next-boundary 15}
    half: {|| next-boundary 30}
    hour: {|| next-boundary 60}
}

def fill-in [name: string] {
    if ($name in $fill_ins) {
        do ($fill_ins | get $name)
    } else {
        error make {msg: $"unknown fill-in: ($name)"}
    }
}

def parse-token [tok: string] {
    let tok = (if ($tok | str starts-with '@') { fill-in ($tok | str substring 1..) } else { $tok })
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

def t-sleep [...tokens: string] {
    let fullTokens = ($tokens | append "-" | append $env.sleepDuration)
    timecalc ...$fullTokens
}

def t-work [--slack: string = "30m", ...tokens: string] {
    let fullTokens = ($tokens | append "-" | append $slack)
    timecalc ...$fullTokens
}

def --env set-sleep-duration [...tokens: string] {
    $env.sleepDuration = (timecalc $env.sleepDuration ...$tokens)
    print $env.sleepDuration
}

def --env set-wake-up-time [...tokens: string] {
    $env.wakeUpTime = (timecalc $env.wakeUpTime ...$tokens)
    print $env.wakeUpTime
}

def t-wake-up-time [...tokens: string] {
    let fullTokens = ("@now" | append "+" | append $env.sleepDuration)
    timecalc ...$fullTokens
}

def t-sleep-free-time [...tokens: string] {
    let sleepTime = if ($tokens | length) > 0 {
        t-sleep ...$tokens
    } else {
        t-sleep $env.wakeUpTime
    }
    let fullTokens = ("@now" | append "to" | append $sleepTime)
    timecalc ...$fullTokens
}
