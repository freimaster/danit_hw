import http.client
import json
import threading
import unittest
from http.server import ThreadingHTTPServer
from unittest.mock import patch

from app.server import APP_VERSION, Handler


class ServerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join()

    def request(self, path):
        connection = http.client.HTTPConnection(*self.server.server_address, timeout=5)
        try:
            connection.request("GET", path)
            response = connection.getresponse()
            return response.status, dict(response.getheaders()), response.read()
        finally:
            connection.close()

    def test_root_returns_200_and_version(self):
        with patch.dict("os.environ", {"APP_REVISION": "test-commit", "APP_VERSION": "ignored"}):
            status, headers, body = self.request("/")
        self.assertEqual(status, 200)
        self.assertEqual(json.loads(body), {
            "status": "ok", "version": APP_VERSION, "revision": "test-commit",
        })
        self.assertEqual(int(headers["Content-Length"]), len(body))
        self.assertIn("application/json", headers["Content-Type"])

    def test_local_revision_defaults_to_dev(self):
        with patch.dict("os.environ", {}, clear=True):
            status, _, body = self.request("/")
        self.assertEqual(status, 200)
        self.assertEqual(json.loads(body)["revision"], "dev")

    def test_root_with_query_string(self):
        self.assertEqual(self.request("/?probe=1")[0], 200)

    def test_unknown_path_returns_404(self):
        self.assertEqual(self.request("/missing")[0], 404)


if __name__ == "__main__":
    unittest.main()
