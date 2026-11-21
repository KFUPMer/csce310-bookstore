"""The real UserServiceSessionChecker, against a small HTTP server standing in for user-service."""
import threading
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from book_service.auth import UserServiceSessionChecker
from book_service.errors import ServiceUnavailableError


class _NotUserService(BaseHTTPRequestHandler):
    """Answers 200 with a web page: another program on user-service's port (P-023)."""

    def do_GET(self):
        body = b"<html>some other program</html>"
        self.send_response(200)
        self.send_header("Content-Type", "text/html")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass  # keep the test output clean


class SessionCheckerTest(unittest.TestCase):
    def setUp(self):
        self.server = ThreadingHTTPServer(("127.0.0.1", 0), _NotUserService)
        threading.Thread(target=self.server.serve_forever, daemon=True).start()
        self.addCleanup(self.server.server_close)
        self.addCleanup(self.server.shutdown)

    def test_an_answer_that_is_not_user_service_is_503_not_a_crash(self):
        checker = UserServiceSessionChecker(f"http://127.0.0.1:{self.server.server_port}")
        with self.assertRaises(ServiceUnavailableError):
            checker.check("some-token")


if __name__ == "__main__":
    unittest.main()
