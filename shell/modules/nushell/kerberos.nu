const KERBEROS_PRINCIPAL = "c.lenoir@I2DEVAD.DE"
const KERBEROS_PASSWORD_FILE = "~/.config/kerberos/dev_vm_password"
const KERBEROS_REFRESH_INTERVAL = 900
const KERBEROS_AUTO_START = true

def _kerberos-password-file [] {
    $KERBEROS_PASSWORD_FILE | path expand
}

def _kerberos-init-bin [] {
    let configured = ($env.KERBEROS_INIT_BIN? | default "")
    if $configured != "" {
        $configured
    } else if ((which ktinit | length) > 0) {
        "ktinit"
    } else {
        "kinit"
    }
}

def _kerberos-expect-script [] {
    $"($env.dotfiles)/shell/modules/shared/kerberos-login.expect"
}

def ktinit-refresh [--force] {
    let principal = $KERBEROS_PRINCIPAL

    if (not $force) {
        let cache_state = (^klist -s | complete)
        if $cache_state.exit_code == 0 {
            return
        }
    }

    let password_file = (_kerberos-password-file)
    if not ($password_file | path exists) {
        error make { msg: $"Kerberos password file is missing: ($password_file)" }
    }

    let init_bin = (_kerberos-init-bin)
    if ((which $init_bin | length) == 0) {
        error make { msg: $"Kerberos init command not found: ($init_bin)" }
    }

    let expect_script = (_kerberos-expect-script)
    if not ($expect_script | path exists) {
        error make { msg: $"Kerberos expect script is missing: ($expect_script)" }
    }

    let result = (^expect $expect_script $init_bin $principal $password_file | complete)
    if $result.exit_code != 0 {
        let stderr = ($result.stderr | str trim)
        let stdout = ($result.stdout | str trim)
        if $stderr == "" and $stdout == "" {
            error make { msg: $"Failed to acquire Kerberos ticket via ($init_bin)" }
        } else if $stderr == "" {
            error make { msg: $stdout }
        } else {
            error make { msg: $stderr }
        }
    }
}

def ktinit-ensure [] {
    let result = (^klist -s | complete)
    if $result.exit_code != 0 {
        ktinit-refresh
    }
}

def ktinit-watch [interval?: int] {
    let refresh_interval = ($interval | default $KERBEROS_REFRESH_INTERVAL)
    if $refresh_interval <= 0 {
        error make { msg: "Refresh interval must be a positive integer" }
    }

    loop {
        do --ignore-errors { ktinit-ensure }
        sleep ($refresh_interval | into duration --unit sec)
    }
}

def --env ktinit-watch-start [interval?: int] {
    let existing = ($env.KERBEROS_WATCH_JOB_ID? | default null)
    if ($existing | describe) == "int" and $existing >= 0 {
        let running = (job list | where id == $existing | length)
        if $running > 0 {
            $existing
            return
        }
    }

    let refresh_interval = ($interval | default $KERBEROS_REFRESH_INTERVAL)
    if $refresh_interval <= 0 {
        error make { msg: "Refresh interval must be a positive integer" }
    }

    let id = (job spawn --description "kerberos ticket refresher" { ktinit-watch $refresh_interval })
    $env.KERBEROS_WATCH_JOB_ID = $id
    $id
}

def --env ktinit-watch-stop [] {
    let existing = ($env.KERBEROS_WATCH_JOB_ID? | default null)
    if ($existing | describe) == "int" and $existing >= 0 {
        let running = (job list | where id == $existing | length)
        if $running > 0 {
            job kill $existing
        }
    }

    $env.KERBEROS_WATCH_JOB_ID = null
}

if $nu.is-interactive and $KERBEROS_AUTO_START {
    do --ignore-errors { ktinit-watch-start | ignore }
}
