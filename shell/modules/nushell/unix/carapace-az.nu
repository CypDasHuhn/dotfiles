if (which az | is-empty) {
    null
} else {
    $env.config.completions.external.completer = {|place|
        let command = $place.command
        if (($command | is-empty) or $command.0 != "az") {
            null
        } else {
            let line = ($command | str join " ")
            let completion_file = ($nu.cache-dir | path join $"az-native-completions-($nu.pid)")
            mkdir $nu.cache-dir | ignore
            rm --force $completion_file
            with-env {
                _ARGCOMPLETE: "1"
                _ARGCOMPLETE_IFS: "\n"
                _ARGCOMPLETE_STDOUT_FILENAME: $completion_file
                _ARGCOMPLETE_SUPPRESS_SPACE: "1"
                COMP_LINE: $line
                COMP_POINT: ($line | str length | into string)
            } { ^az } | complete | ignore
            if ($completion_file | path exists) {
                let completions = (open $completion_file | lines)
                rm --force $completion_file
                $completions | each {|value| {value: $value, display: $value, description: ""}}
            } else {
                null
            }
        }
    }
}
