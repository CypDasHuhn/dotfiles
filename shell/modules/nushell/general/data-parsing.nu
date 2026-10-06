def schema [] {
    let v = $in
    let t = ($v | describe)
    let is_container = ($t | str starts-with "list") or ($t | str starts-with "table")

    if ($t | str starts-with "record") {
        $v | transpose key value | update value {|row| $row.value | schema}
    } else if $is_container {
        if ($v | is-empty) {
            $t
        } else {
            $v | first | schema
        }
    } else {
        $t
    }
}
