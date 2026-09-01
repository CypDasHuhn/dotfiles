return {
    name = "sshd",
    description = "SSH daemon (user-level)",
    command = {
        "sshd",
        "-D",
        "-f",
        "${HOME}/.ssh/sshd_config",
        "-h",
        "${HOME}/.ssh/ssh_host_ed25519_key",
    },
    restart = "on-failure",
    wanted_by = "default.target",
    only = { os = "unix" },
}
