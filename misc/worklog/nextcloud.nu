const nextcloud_origin = "https://nextcloud.i2solutions.de"
const remote_dir = "device-work"

def credentials [] {
    let user = $env.I2_NEXT_CLOUD_USER? | default ""
    let password = $env.I2_NEXT_CLOUD_PASSWORD? | default ""

    if ($user | is-empty) or ($password | is-empty) {
        error make {
            msg: "Nextcloud credentials are not available"
            help: "Set I2_NEXT_CLOUD_USER and I2_NEXT_CLOUD_PASSWORD in the Nushell secrets file."
        }
    }

    if ($user =~ '[\r\n]') or ($password =~ '[\r\n]') {
        error make { msg: "Nextcloud credentials must not contain newlines" }
    }

    { user: $user, password: $password }
}

def curl-config [] {
    let auth = credentials
    let escaped = $"($auth.user):($auth.password)"
        | str replace --all '\\' '\\\\'
        | str replace --all '"' '\\"'
    let temp_dir = [$env.TMPDIR? $env.TEMP? $env.TMP? "/tmp"] | compact | first
    let config_file = $temp_dir | path join $"worklog-curl-($nu.pid)-((random chars --length 12)).conf"

    $"user = \"($escaped)\"\n" | save --force $config_file
    ^chmod 600 $config_file
    $config_file
}

def validate-name [name: string] {
    if ($name | is-empty) or ($name in [. ..]) or ($name =~ '[/\\]') {
        error make { msg: $"Invalid device-work filename: ($name)" }
    }
}

def remote-url [name?: string] {
    let auth = credentials
    mut segments = [$auth.user $remote_dir]

    if $name != null {
        validate-name $name
        $segments = $segments | append $name
    }

    let path = $segments | each { url encode } | str join "/"
    $"($nextcloud_origin)/remote.php/dav/files/($path)"
}

def request [
    method: string
    name?: string
    --depth: int
    --upload-file: path
] {
    if (which curl | is-empty) {
        error make { msg: "curl is required for Nextcloud WebDAV access" }
    }

    let config_file = curl-config
    let url = remote-url $name
    mut args = [
        --config $config_file
        --silent
        --show-error
        --fail-with-body
        --retry 2
        --retry-all-errors
        --connect-timeout 15
        --max-time 120
        --request $method
    ]

    if $depth != null {
        $args = $args | append [--header $"Depth: ($depth)"]
    }

    if $upload_file != null {
        $args = $args | append [--upload-file $upload_file]
    }

    let command_args = $args | append $url
    let result = do { ^curl ...$command_args } | complete
    rm --force $config_file

    if $result.exit_code != 0 {
        let details = [$result.stderr $result.stdout]
            | each { str trim }
            | where { not ($in | is-empty) }
            | str join "\n"
        error make { msg: $"Nextcloud ($method) request failed", help: $details }
    }

    $result.stdout
}

export def list-device-work [] {
    let xml = request PROPFIND --depth 1
    let responses = $xml | parse --regex '(?s)<(?:[A-Za-z0-9_-]+:)?response(?:\s[^>]*)?>(?<body>.*?)</(?:[A-Za-z0-9_-]+:)?response>'

    $responses | each {|response|
        let href_match = $response.body | parse --regex '(?s)<(?:[A-Za-z0-9_-]+:)?href(?:\s[^>]*)?>(?<href>.*?)</(?:[A-Za-z0-9_-]+:)?href>'
        if ($href_match | is-empty) {
            null
        } else {
            let href = $href_match | get href.0
            let encoded_name = $href
                | str trim --right --char "/"
                | split row "/"
                | last
            {
                name: ($encoded_name | url decode)
                is_directory: ($response.body =~ '<(?:[A-Za-z0-9_-]+:)?collection(?:\s*/?>)')
            }
        }
    } | compact | where name != $remote_dir | uniq-by name | sort-by name
}

export def upload-device-work [file: path, name: string] {
    if not ($file | path exists) {
        error make { msg: $"Upload file does not exist: ($file)" }
    }

    request PUT $name --upload-file $file | ignore
}

export def download-device-work [name: string] {
    request GET $name
}

export def delete-device-work [name: string] {
    request DELETE $name | ignore
}
