def svc-dotfiles [] {
    let configured = ($env | get --optional dotfiles)
    if $configured != null {
        $configured
    } else {
        $env.HOME | path join "dotfiles"
    }
}

def svc-services-dir [] {
    svc-dotfiles | path join "unix" "services"
}

def svc-generated-dir [] {
    svc-services-dir | path join "generated"
}

def svc-manifest-path [] {
    svc-generated-dir | path join "services.nuon"
}

def svc-user-unit-dir [] {
    $env.HOME | path join ".config" "systemd" "user"
}

def svc-unit-name [name: string] {
    if ($name | str ends-with ".service") {
        $name
    } else {
        $"dotfiles-($name).service"
    }
}

def svc-logical-name [unit: string] {
    $unit | str replace "dotfiles-" "" | str replace ".service" ""
}

def svc-known-services [] {
    let manifest = (svc-manifest-path)
    if ($manifest | path exists) {
        open ($manifest)
    } else {
        []
    }
}

def svc-known-service [name: string] {
    let unit = (svc-unit-name $name)
    let known = (
        svc-known-services
        | where unit == $unit
    )

    if ($known | is-empty) {
        {
            name: (svc-logical-name $unit),
            unit: $unit,
            description: ""
        }
    } else {
        $known | first
    }
}

def svc-unit-state [unit: string] {
    let enabled = (^systemctl --user is-enabled $unit | complete)
    let active = (^systemctl --user is-active $unit | complete)
    {
        enabled: (if $enabled.exit_code == 0 { $enabled.stdout | str trim } else { "disabled" }),
        active: (if $active.exit_code == 0 { $active.stdout | str trim } else { "inactive" }),
    }
}

def svc-unit-record [service] {
    let unit = $service.unit
    let target = (svc-user-unit-dir | path join $unit)
    let generated = (svc-generated-dir | path join $unit)
    let state = (svc-unit-state $unit)
    {
        name: $service.name,
        unit: $unit,
        enabled: $state.enabled,
        active: $state.active,
        linked: ($target | path exists),
        generated: ($generated | path exists),
        description: $service.description,
    }
}

def "svc sync" [] {
    let bootstrap = (svc-services-dir | path join "bootstrap.lua")
    let result = (^lua $bootstrap | complete)

    if $result.exit_code != 0 {
        if ($result.stderr | str trim | is-not-empty) { print ($result.stderr | str trim) }
        error make { msg: "Service sync failed." }
    }

    if ($result.stdout | str trim | is-not-empty) {
        print ($result.stdout | str trim)
    }

    ^systemctl --user daemon-reload
    svc list
}

def "svc list" [] {
    svc-known-services | each { |service| svc-unit-record $service }
}

def "svc status" [name: string] {
    let service = (svc-known-service $name)
    ^systemctl --user status $service.unit
}

def "svc enable" [name: string] {
    let service = (svc-known-service $name)
    ^systemctl --user enable --now $service.unit
}

def "svc disable" [name: string] {
    let service = (svc-known-service $name)
    ^systemctl --user disable --now $service.unit
}

def "svc restart" [name: string] {
    let service = (svc-known-service $name)
    ^systemctl --user restart $service.unit
}

def "svc logs" [
    name: string,
    --follow (-f),
] {
    let service = (svc-known-service $name)
    if $follow {
        ^journalctl --user -fu $service.unit
    } else {
        ^journalctl --user -u $service.unit -n 100
    }
}

def svc [] {
    svc list
}
