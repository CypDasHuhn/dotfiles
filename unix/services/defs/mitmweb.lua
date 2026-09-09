return {
    name = "mitmweb",
    description = "Headless mitmproxy",
    command = {
        "mitmdump",
        "--quiet",
        "--listen-host",
        "127.0.0.1",
        "--listen-port",
        "8080",
        "-s",
        "~/.config/mitmproxy/reddit_filter.py",
        "--set",
        "ssl_insecure=true",
    },
    restart = "on-failure",
    environment = {
        PYTHONPYCACHEPREFIX = "${HOME}/.cache/python",
    },
    wanted_by = "default.target",
    only = { os = "unix" },
}
