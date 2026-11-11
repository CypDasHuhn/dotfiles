def kerberos-renewer-script [] {
    $env.dotfiles | path join "shell" "modules" "nushell" "startup" "kerberos-renewer.nu"
}

def ensure-i2-kerberos [] {
    let result = (do { ^nu --no-config-file (kerberos-renewer-script) --once } | complete)
    if $result.exit_code != 0 {
        error make { msg: "Kerberos authentication failed." }
    }
}

def start-i2-kerberos-renewer [] {
    let runtime = ($env.XDG_RUNTIME_DIR? | default ($nu.home-dir | path join ".cache"))
    if not ($runtime | path exists) {
        mkdir $runtime
    }

    let lock = ($runtime | path join "i2-kerberos-renewer.lock")
    let log = ($runtime | path join "i2-kerberos-renewer.log")
    let command = $"nohup flock -n ($lock) nu --no-config-file (kerberos-renewer-script) >> ($log) 2>&1 < /dev/null &"
    job spawn {
        ^bash -c $command
    } | ignore
}

if (($env.I2_AD_USER? != null) and ($env.I2_AD_PASSWORD_2? != null)) {
    start-i2-kerberos-renewer
}
