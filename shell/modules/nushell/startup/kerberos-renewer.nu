def authenticate [] {
    if ("I2_AD_USER" not-in $env) or ("I2_AD_PASSWORD_2" not-in $env) {
        return false
    }

    let result = (with-env {
        I2_KINIT_USER: $env.I2_AD_USER
        I2_KINIT_PASSWORD: $env.I2_AD_PASSWORD_2
    } {
        ^expect -c '
            log_user 0
            set timeout 30
            spawn kinit $env(I2_KINIT_USER)
            expect {
                -re {Password for .*:} {
                    send -- "$env(I2_KINIT_PASSWORD)\r"
                    exp_continue
                }
                eof {
                    catch wait result
                    exit [lindex $result 3]
                }
                timeout { exit 1 }
            }
        '
        | complete
    })

    $result.exit_code == 0
}

def renew [] {
    let renewed = (do { ^kinit -R } | complete)
    if $renewed.exit_code == 0 {
        return true
    }

    let valid = (do { ^klist -s } | complete)
    if $valid.exit_code == 0 {
        return true
    }

    authenticate
}

def main [--once] {
    if $once {
        if (renew) {
            exit 0
        }
        exit 1
    }

    loop {
        let ok = (renew)
        if $ok {
            sleep 5min
        } else {
            sleep 1min
        }
    }
}
