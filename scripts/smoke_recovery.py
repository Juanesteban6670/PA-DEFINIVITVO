"""Capture test-only mail locally, or verify the reset lifecycle against test data."""
import argparse
from html.parser import HTMLParser
from http.server import BaseHTTPRequestHandler, HTTPServer
import json
from pathlib import Path
import time
from urllib.error import HTTPError
from urllib.parse import parse_qs, urlsplit
from urllib.request import Request, urlopen


class ResetLinkParser(HTMLParser):
    link = None

    def handle_starttag(self, tag, attrs):
        href = dict(attrs).get("href")
        if tag == "a" and href and urlsplit(href).fragment.startswith("/ResetPassword?"):
            self.link = href


def mailbox(destination):
    class MailHandler(BaseHTTPRequestHandler):
        def do_POST(self):
            payload = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
            if payload.get("to") == "render-smoke@example.com":
                parser = ResetLinkParser()
                parser.feed(payload.get("html", ""))
                if parser.link:
                    pending = destination.with_suffix(".pending")
                    pending.write_text(parser.link)
                    pending.replace(destination)
            self.send_response(200)
            self.end_headers()

        def log_message(self, *_args):
            pass

    HTTPServer(("0.0.0.0", 18081), MailHandler).serve_forever()


def verify(base, destination):
    def post(path, data):
        request = Request(base + "/api/Auth/" + path, data=json.dumps(data).encode(),
                          headers={"Content-Type": "application/json"})
        try:
            with urlopen(request, timeout=12) as response:
                return response.status
        except HTTPError as error:
            return error.code

    assert post("ForgotPassword", {"email": "render-smoke@example.com"}) == 200
    for _ in range(30):
        if destination.exists():
            break
        time.sleep(1)
    assert destination.exists(), "The isolated mailbox did not receive a reset link"
    link = urlsplit(destination.read_text())
    base_url = urlsplit(base)
    assert (link.scheme, link.netloc, link.path) == (base_url.scheme, base_url.netloc, "/")
    token = parse_qs(urlsplit(link.fragment).query).get("token", [""])[0]
    assert token, "Reset link omitted its token"
    change = {"token": token, "newPassword": "QA-new-only-123!"}
    assert post("ResetPassword", change) == 200
    assert post("Login", {"username": "ci_render_smoke", "password": change["newPassword"]}) == 200
    assert post("Login", {"username": "ci_render_smoke", "password": "CI-only-pass-123!"}) in (400, 401, 403)
    assert post("ResetPassword", change) in (400, 401, 403, 404)
    destination.unlink()
    print("Isolated email, password reset, new login and token reuse checks passed.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=["mailbox", "verify"])
    parser.add_argument("capture", type=Path)
    parser.add_argument("--base")
    args = parser.parse_args()
    if args.mode == "mailbox":
        mailbox(args.capture)
    else:
        verify(args.base, args.capture)


if __name__ == "__main__":
    main()
