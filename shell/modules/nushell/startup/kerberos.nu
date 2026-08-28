def ensure-i2-kerberos [] {
    let ticket = (^klist -s | complete)
    if $ticket.exit_code == 0 {
        return
    }

    if "I2_AD_USER" not-in $env {
        error make { msg: "I2_AD_USER is not set." }
    }
    if "I2_AD_PASSWORD_2" not-in $env {
        error make { msg: "I2_AD_PASSWORD_2 is not set." }
    }

    # MIT kinit reads passwords from its controlling TTY, not stdin. `expect`
    # gives it a private pseudo-terminal, so neither the prompt nor password is
    # written to this shell.
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

    if $result.exit_code != 0 {
        error make { msg: "Kerberos authentication failed." }
    }
}

if (($env.I2_AD_USER? != null) and ($env.I2_AD_PASSWORD_2? != null)) {
    ensure-i2-kerberos
}
