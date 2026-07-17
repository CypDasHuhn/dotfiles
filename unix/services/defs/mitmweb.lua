return {
    name = "mitmweb",
    description = "Mitmweb proxy",
    command = {
        "mitmweb",
        "--listen-port",
        "8080",
        "-s",
        "~/.config/mitmproxy/reddit_filter.py",
    },
    restart = "on-failure",
    wanted_by = "default.target",
    only = { os = "unix" },
}
