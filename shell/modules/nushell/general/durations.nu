def hr-to-clock [] {
    let h2 = ($in mod 24 | if $in < 0 { $in + 24 } else { $in })
    let hh = ($h2 | math floor)
    let mm = ((($h2 - $hh) * 60) | math round)
    $"($hh | fill -a right -c '0' -w 2):($mm | fill -a right -c '0' -w 2)"
}
def wrap-hours [] {
    let r = $in mod 24
    if $r < 0 { $r + 24 } else { $r }
}

alias whr = wrap-hours

def wrap-hours-to-clock [] {
  wrap-hours | hr-to-clock
}
alias wh = wrap-hours-to-clock 
