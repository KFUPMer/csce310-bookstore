"""The client that talks to book-service, against a small web server that answers like it.

The stand-in server speaks real HTTP on a free local port, so the address, the
header, the body, and the reading of each answer are all exercised. Calling the
real book-service is done in the manual check (see the README).
"""
import logging
import threading
import unittest
from decimal import Decimal

from flask import Flask, jsonify, request
from werkzeug.serving import make_server

from order_service.catalog import BookServiceCatalog
from order_service.errors import ConflictError, NotFoundError, ServiceUnavailableError

KEY = "test-service-key"
BOOK = "a" * 24
GONE = "f" * 24


def stand_in_book_service(copies: dict) -> Flask:
    app = Flask(__name__)

    @app.patch("/api/books/<book_id>/copies")
    def change_copies(book_id):
        if request.headers.get("X-Service-Key") != KEY:
            return jsonify(error="This address is for the bookstore's own services only"), 403
        if book_id not in copies:
            return jsonify(error="This book does not exist"), 404
        change = request.get_json()["change"]
        if copies[book_id] + change < 0:
            return jsonify(error='"Clean Code" is not available'), 409
        copies[book_id] += change
        return jsonify(id=book_id, title="Clean Code", author="Robert C. Martin", price=40.1, copiesAvailable=copies[book_id], coverUrl=None)

    return app


class BookServiceCatalogTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        logging.getLogger("werkzeug").setLevel(logging.ERROR)  # the stand-in server's request log is noise here
        cls.copies = {}
        cls.server = make_server("127.0.0.1", 0, stand_in_book_service(cls.copies))
        cls.url = f"http://127.0.0.1:{cls.server.server_port}"
        threading.Thread(target=cls.server.serve_forever, daemon=True).start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()

    def setUp(self):
        self.copies.clear()
        self.copies[BOOK] = 3
        self.catalog = BookServiceCatalog(self.url, KEY)

    def test_take_reduces_the_copies_and_returns_the_book(self):
        book = self.catalog.take(BOOK, 2)
        self.assertEqual(self.copies[BOOK], 1)
        self.assertEqual((book.id, book.title, book.author), (BOOK, "Clean Code", "Robert C. Martin"))

    def test_the_price_is_exact_money_not_a_float(self):
        self.assertEqual(self.catalog.take(BOOK, 1).price, Decimal("40.10"))

    def test_give_back_returns_the_copies(self):
        self.catalog.take(BOOK, 2)
        self.catalog.give_back(BOOK, 2)
        self.assertEqual(self.copies[BOOK], 3)

    def test_an_unknown_book_is_not_found(self):
        with self.assertRaises(NotFoundError) as raised:
            self.catalog.take(GONE, 1)
        self.assertEqual(raised.exception.message, "This book does not exist")

    def test_not_enough_copies_is_a_conflict_with_book_services_message(self):
        with self.assertRaises(ConflictError) as raised:
            self.catalog.take(BOOK, 4)
        self.assertEqual(raised.exception.message, '"Clean Code" is not available')
        self.assertEqual(self.copies[BOOK], 3)

    def test_a_wrong_service_key_is_unavailable_not_forbidden(self):
        # The customer did nothing wrong: this is a set-up fault on our side.
        with self.assertLogs("order_service.catalog", level="ERROR") as logs:
            with self.assertRaises(ServiceUnavailableError):
                BookServiceCatalog(self.url, "wrong-key").take(BOOK, 1)
        self.assertIn("403", logs.output[0])
        self.assertNotIn("wrong-key", logs.output[0])

    def test_book_service_not_running_is_unavailable(self):
        with self.assertRaises(ServiceUnavailableError) as raised:
            BookServiceCatalog("http://127.0.0.1:9", KEY).take(BOOK, 1)
        self.assertEqual(raised.exception.message, "The book catalog is not answering. Please try again in a moment.")


if __name__ == "__main__":
    unittest.main()
