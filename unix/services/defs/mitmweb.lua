return {
    name = "mitmweb",
    description = "Mitmweb proxy",
    command = {
        "mitmweb",
        "--listen-port",
        "8080",
        "-s",
        "~/.config/mitmproxy/reddit_filter.py",
        "--set",
        "ssl_insecure=true",
    },
    restart = "on-failure",
    environment = {
        -- mitmproxy imports reddit_filter.py from the symlinked config dir, so
        -- CPython would otherwise drop __pycache__ inside the dotfiles repo.
        PYTHONPYCACHEPREFIX = "${HOME}/.cache/python",
    },
    wanted_by = "default.target",
    only = { os = "unix" },
}
