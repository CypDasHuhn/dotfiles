#!/usr/bin/env nu

use nextcloud.nu upload-device-work
use period.nu resolve-period

const script_dir = path self .
const repo_root = path self ../..
const worklog_timezone = "Europe/Berlin"

def machine-name [] {
    let result = do {
        cd $repo_root
        ^lua -e 'local machine = dofile(".machine.local.lua"); assert(type(machine.name) == "string" and machine.name ~= ""); io.write(machine.name)'
    } | complete

    if $result.exit_code != 0 {
        error make { msg: "Could not read machine name from .machine.local.lua", help: ($result.stderr | str trim) }
    }

    let name = $result.stdout | str trim
    if ($name | is-empty) or ($name =~ '[/\\]') {
        error make { msg: $"Machine name is not safe for a filename: ($name)" }
    }

    $name
}

def fields-from [values: list<string>] {
    mut fields = {}

    for value in $values {
        let field_value = unquote $value
        let matches = $field_value | parse --regex '^(?<key>[A-Za-z][A-Za-z0-9_.-]*)=(?<value>.*)$'
        if ($matches | is-empty) {
            error make {
                msg: $"Invalid field: ($field_value)"
                help: "Fields must use key=value syntax, for example project=cvm."
            }
        }

        let field = $matches | first
        if ($fields | columns | any {|key| $key == $field.key }) {
            error make { msg: $"Field is specified more than once: ($field.key)" }
        }
        $fields = $fields | upsert $field.key (unquote $field.value)
    }

    $fields
}

def unquote [value: string] {
    let double_quoted = $value | parse --regex '^"(?<text>.*)"$'
    if not ($double_quoted | is-empty) {
        return ($double_quoted | first | get text)
    }

    let single_quoted = $value | parse --regex "^'(?<text>.*)'$"
    if not ($single_quoted | is-empty) {
        return ($single_quoted | first | get text)
    }

    $value
}

export def main [
    text: string
    ...field: string
    --output: path
    --no-upload
    --from: string
    --to: string
    --retrospective
] {
    let trimmed_text = unquote ($text | str trim)
    if ($trimmed_text | is-empty) {
        error make { msg: "The log text must not be empty" }
    }

    let machine = machine-name
    let logged_at = date now | date to-timezone $worklog_timezone
    if $retrospective and (($from == null) or ($to == null)) {
        error make {
            msg: "A retrospective requires both --from and --to"
            help: "Use --from YYYY-MM-DD --to YYYY-MM-DD."
        }
    }
    if (not $retrospective) and (($from != null) or ($to != null)) {
        error make { msg: "Date ranges are only supported by worklog retrospective" }
    }

    let period = resolve-period "" $from $to
    let source = if $retrospective { "retrospective" } else { "personal-log" }
    let unique = random chars --length 8
    let remote_name = $"($source)-($machine)-($logged_at | format date '%Y-%m-%dT%H-%M-%S')-($unique)-($period.start_date):($period.end_date).json"
    let output_file = $output | default (
        $script_dir | path join generated ($remote_name | str replace ":" "_")
    )
    let document = {
        source: $source
        machine: $machine
        from: $period.start_date
        to: $period.end_date
        timestamp: ($logged_at | format date "%Y-%m-%dT%H:%M:%S%:z")
        text: $trimmed_text
        fields: (fields-from $field)
    }

    mkdir ($output_file | path dirname)
    $document | to json --indent 2 | save --force $output_file
    print $"Saved ($source) to ($output_file | path expand)"

    if not $no_upload {
        upload-device-work $output_file $remote_name
        print $"Uploaded ($source) to Nextcloud device-work/($remote_name)"
    }
}
