"""A small, dependency-free HTTP backend for the EKS demo v4."""

import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlsplit

APP_VERSION = "v5"


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if urlsplit(self.path).path != "/":
            self.send_error(404)
            return
        body = json.dumps({
            "status": "ok",
            "version": APP_VERSION,
            "revision": os.getenv("APP_REVISION", "dev"),
        }).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def main():
    port = int(os.getenv("PORT", "8000"))
    with ThreadingHTTPServer(("0.0.0.0", port), Handler) as server:
        print(f"Listening on 0.0.0.0:{port}", flush=True)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass


if __name__ == "__main__":
    main()
