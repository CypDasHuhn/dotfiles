import re
from mitmproxy import http

REDDIT_HOSTS = {"www.reddit.com", "old.reddit.com", "reddit.com", "sh.reddit.com"}
ALLOW_PATTERN = re.compile(r"^(/r/[^/]+/comments/[^/]+|/svc/)")

def request(flow: http.HTTPFlow):
    host = flow.request.pretty_host
    if host in REDDIT_HOSTS:
        if not ALLOW_PATTERN.match(flow.request.path):
            flow.response = http.Response.make(
                403,
                b"Blocked: not a post page.",
                {"Content-Type": "text/plain"}
            )
