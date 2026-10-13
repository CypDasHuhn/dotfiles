#!/usr/bin/env nu

use period.nu resolve-period
use nextcloud.nu upload-device-work

const script_dir = path self .

def default-extractor [] {
    $nu.home-dir | path join source repos msteams-history-extractor
}

def result-details [result: record] {
    [$result.stderr $result.stdout]
        | each { str trim }
        | where { not ($in | is-empty) }
        | str join "\n"
}

def main [
    --from: string
    --to: string
    --extractor: path
    --leveldb: path
    --output: path
    --no-upload
] {
    if ($from == null) or ($to == null) {
        error make {
            msg: "Both --from and --to are required"
            help: "Use --from YYYY-MM-DD --to YYYY-MM-DD."
        }
    }

    let period = resolve-period "" $from $to
    let remote_name = $"msteams-($period.start_date):($period.end_date).json"
    let extractor_dir = $extractor | default (default-extractor)
    let extractor_script = $extractor_dir | path join extract.py

    if not ($extractor_dir | path exists) {
        error make { msg: $"MS Teams extractor directory does not exist: ($extractor_dir | path expand)" }
    }

    if not ($extractor_script | path exists) {
        error make { msg: $"MS Teams extractor entry point does not exist: ($extractor_script | path expand)" }
    }

    if (which python | is-empty) {
        error make { msg: "python is required to run the MS Teams extractor" }
    }

    let output_file = $output | default (
        $script_dir
            | path join generated $"msteams-($period.start_date)_($period.end_date).json"
    )
    mkdir ($output_file | path dirname)

    let raw_dir = $nu.temp-dir | path join $"msteams-worklog-($nu.pid)-((random chars --length 12))"
    mkdir $raw_dir
    let calls_file = $raw_dir | path join calls.json
    let messages_file = $raw_dir | path join messages.json
    let end_exclusive = $period.end_exclusive | format date "%Y-%m-%d"

    mut extractor_args = [
        extract.py
        --after $period.start_date
        --before $end_exclusive
        --calls $calls_file
        --messages $messages_file
    ]
    if $leveldb != null {
        $extractor_args = $extractor_args | append [--leveldb $leveldb]
    }

    let command_args = $extractor_args
    let result = do {
        cd $extractor_dir
        ^python ...$command_args
    } | complete

    if $result.exit_code != 0 {
        rm --recursive --force $raw_dir
        error make { msg: "MS Teams extraction failed", help: (result-details $result) }
    }

    let document = {
        source: "msteams"
        name: "msteams"
        from: $period.start_date
        to: $period.end_date
        generated: (date now | format date "%Y-%m-%dT%H:%M:%S%:z")
        calls: (open --raw $calls_file | from json)
        messages: (open --raw $messages_file | from json)
    }
    $document | to json --indent 2 | save --force $output_file
    rm --recursive --force $raw_dir

    let extractor_output = $result.stdout | str trim
    if not ($extractor_output | is-empty) {
        print $extractor_output
    }
    print $"Saved MS Teams worklog to ($output_file | path expand)"

    if not $no_upload {
        upload-device-work $output_file $remote_name
        print $"Uploaded MS Teams worklog to Nextcloud device-work/($remote_name)"
    }
}

