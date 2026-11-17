"""Every endpoint, called the way the apps will: success and each error.

Uses Flask's test client with an in-memory repository, stand-ins for
user-service, book-service and the mail server, and a temporary folder for the
bills, so no database and no other service is needed.
"""
import tempfile
import unittest
from datetime import datetime
from pathlib import Path

from order_service.app import create_app
from order_service.bill import BillStore
from order_service.repository import InMemoryOrderRepository

from .fakes import FakeCatalog, FakeSessionChecker, RecordingMailer, as_alice, as_manager, as_omar

NOW = datetime(2026, 11, 13, 10, 5, 0)
UNKNOWN_BOOK = "f" * 24


class BrokenRepository(InMemoryOrderRepository):
    """A database that fails when an order is saved."""

    def save(self, order):
        raise RuntimeError("the database is gone")


class ApiTest(unittest.TestCase):
    def setUp(self):
        self.folder = tempfile.TemporaryDirectory()
        self.addCleanup(self.folder.cleanup)
        self.bills_folder = Path(self.folder.name) / "bills"
        self.repository = InMemoryOrderRepository()
        self.sessions = FakeSessionChecker()
        self.catalog = FakeCatalog()
        self.mailer = RecordingMailer()
        self.now = NOW
        self.client = self.make_client(self.repository)

        self.clean_code = self.catalog.add(1, "Clean Code", "Robert C. Martin", "40.00", 4)
        self.database = self.catalog.add(2, "Database System Concepts", "Abraham Silberschatz", "55.00", 2)
        self.concurrency = self.catalog.add(3, "Java Concurrency in Practice", "Brian Goetz", "80.00", 1)
        self.sold_out = self.catalog.add(4, "MongoDB: The Definitive Guide", "Shannon Bradshaw", "44.00", 0)

    def make_client(self, repository, bills_folder=None):
        app = create_app(repository, self.catalog, self.sessions, BillStore(bills_folder or self.bills_folder), self.mailer, clock=lambda: self.now)
        return app.test_client()

    def place(self, *items, headers=None, client=None):
        body = {"items": [{"bookId": book_id, "type": kind} for book_id, kind in items]}
        return (client or self.client).post("/api/orders", json=body, headers=headers or as_alice())

    def assert_error(self, response, status, message):
        self.assertEqual(response.status_code, status, response.get_data(as_text=True))
        self.assertEqual(response.get_json(), {"error": message})

    def assert_nothing_was_ordered(self):
        self.assertEqual(self.repository.list_all(), [], "no order was saved")
        self.assertEqual(list(self.catalog.copies.values()), [4, 2, 1, 0], "every copy is back")
        self.assertEqual(self.mailer.sent, [], "no email was sent")

    # ------------------------------------------------------------ place an order (FR6, FR7, FR8)

    def test_placing_an_order_answers_with_the_order_and_its_bill(self):
        response = self.place((self.clean_code, "BUY"), (self.database, "BUY"), (self.concurrency, "RENT"))
        self.assertEqual(response.status_code, 201, response.get_data(as_text=True))
        order = response.get_json()
        bill_html = order.pop("billHtml")
        self.assertEqual(order, {
            "id": 1001,
            "username": "alice",
            "email": "alice@example.com",
            "createdAt": "2026-11-13T10:05:00",
            "paymentStatus": "PENDING",
            "items": [
                {"title": "Clean Code", "author": "Robert C. Martin", "type": "BUY", "quantity": 1, "unitPrice": 40.0, "rentDueDate": None},
                {"title": "Database System Concepts", "author": "Abraham Silberschatz", "type": "BUY", "quantity": 1, "unitPrice": 55.0, "rentDueDate": None},
                {"title": "Java Concurrency in Practice", "author": "Brian Goetz", "type": "RENT", "quantity": 1, "unitPrice": 8.0, "rentDueDate": "2026-11-20"},
            ],
            "total": 103.0,
            "billFile": "bills/bill-1001.html",
            "emailQueued": True,
        })
        self.assertIn("Total amount due</td><td class=\"num\">$103.00</td>", bill_html)

    def test_placing_an_order_takes_one_copy_of_each_book(self):
        self.place((self.clean_code, "BUY"), (self.concurrency, "RENT"))
        self.assertEqual(self.catalog.copies[self.clean_code], 3)
        self.assertEqual(self.catalog.copies[self.concurrency], 0)
        self.assertEqual(self.catalog.copies[self.database], 2, "a book that was not ordered is untouched")

    def test_the_bill_is_saved_as_an_html_file(self):
        bill_html = self.place((self.clean_code, "BUY")).get_json()["billHtml"]
        saved = self.bills_folder / "bill-1001.html"
        self.assertEqual(saved.read_text(encoding="utf-8"), bill_html)

    def test_the_bill_is_emailed_to_the_customer(self):
        bill_html = self.place((self.clean_code, "BUY")).get_json()["billHtml"]
        self.assertEqual(len(self.mailer.sent), 1)
        order, emailed_html = self.mailer.sent[0]
        self.assertEqual((order.id, order.email), (1001, "alice@example.com"))
        self.assertEqual(emailed_html, bill_html)

    def test_a_failed_email_does_not_fail_the_order(self):
        self.mailer.broken = True
        with self.assertLogs("order_service.services", level="ERROR"):  # the failure is logged, not hidden
            response = self.place((self.clean_code, "BUY"))
        self.assertEqual(response.status_code, 201)
        self.assertFalse(response.get_json()["emailQueued"])
        self.assertEqual(len(self.repository.list_all()), 1)

    def test_the_same_book_twice_is_one_line_with_quantity_two(self):
        order = self.place((self.clean_code, "BUY"), (self.clean_code, "BUY")).get_json()
        self.assertEqual([(i["title"], i["quantity"], i["unitPrice"]) for i in order["items"]], [("Clean Code", 2, 40.0)])
        self.assertEqual(order["total"], 80.0)
        self.assertEqual(self.catalog.copies[self.clean_code], 2)

    def test_buying_and_renting_the_same_book_takes_two_copies(self):
        order = self.place((self.clean_code, "BUY"), (self.clean_code, "RENT")).get_json()
        self.assertEqual([(i["type"], i["unitPrice"]) for i in order["items"]], [("BUY", 40.0), ("RENT", 4.0)])
        self.assertEqual(order["total"], 44.0)
        self.assertEqual(self.catalog.copies[self.clean_code], 2)

    def test_each_order_gets_the_next_id(self):
        self.assertEqual(self.place((self.clean_code, "BUY")).get_json()["id"], 1001)
        self.assertEqual(self.place((self.clean_code, "BUY"), headers=as_omar()).get_json()["id"], 1002)

    # ------------------------------------------------------------ an order that cannot be placed

    def test_an_order_needs_at_least_one_book(self):
        self.assert_error(self.client.post("/api/orders", json={"items": []}, headers=as_alice()), 400, "Select at least one book")
        self.assert_error(self.client.post("/api/orders", json={}, headers=as_alice()), 400, "Select at least one book")

    def test_a_type_other_than_buy_or_rent_is_400(self):
        self.assert_error(self.place((self.clean_code, "BORROW")), 400, "Item 1: choose BUY or RENT")
        self.assert_nothing_was_ordered()

    def test_a_book_id_in_the_wrong_format_is_400(self):
        self.assert_error(self.place(("../../x", "BUY")), 400, "Item 1: the book id is not valid")

    def test_a_body_that_is_not_json_is_400(self):
        response = self.client.post("/api/orders", data="not json", headers=as_alice())
        self.assert_error(response, 400, "The request body is not valid JSON")

    def test_a_book_that_does_not_exist_is_404_and_nothing_is_saved(self):
        response = self.place((self.clean_code, "BUY"), (UNKNOWN_BOOK, "BUY"))
        self.assert_error(response, 404, "This book does not exist")
        self.assert_nothing_was_ordered()

    def test_a_book_with_no_copies_is_409_and_nothing_is_saved(self):
        response = self.place((self.clean_code, "BUY"), (self.database, "RENT"), (self.sold_out, "BUY"))
        self.assert_error(response, 409, '"MongoDB: The Definitive Guide" is not available')
        self.assert_nothing_was_ordered()

    def test_more_copies_than_there_are_is_409(self):
        response = self.place((self.concurrency, "BUY"), (self.concurrency, "RENT"))
        self.assert_error(response, 409, '"Java Concurrency in Practice" is not available')
        self.assert_nothing_was_ordered()

    def test_when_book_service_is_down_the_answer_is_503_and_nothing_is_saved(self):
        self.catalog.down = True
        self.assert_error(self.place((self.clean_code, "BUY")), 503, "The book catalog is not answering. Please try again in a moment.")
        self.assert_nothing_was_ordered()

    def test_when_saving_fails_the_copies_are_given_back(self):
        client = self.make_client(BrokenRepository())
        with self.assertLogs("order_service.errors", level="ERROR") as logs:
            response = self.place((self.clean_code, "BUY"), (self.concurrency, "RENT"), client=client)
        self.assert_error(response, 500, "Something went wrong on the server. Please try again.")
        self.assertIn("the database is gone", logs.output[0], "the details are in the log, not in the answer")
        self.assert_nothing_was_ordered()

    def test_when_the_bill_file_cannot_be_written_the_order_still_succeeds(self):
        blocked = Path(self.folder.name) / "not-a-folder"
        blocked.write_text("a file where the bills folder should be")
        client = self.make_client(self.repository, bills_folder=blocked)
        with self.assertLogs("order_service.services", level="ERROR"):
            response = self.place((self.clean_code, "BUY"), client=client)
        self.assertEqual(response.status_code, 201, response.get_data(as_text=True))
        self.assertIsNone(response.get_json()["billFile"])
        self.assertIn("Clean Code", response.get_json()["billHtml"])
        # The bill can still be opened: it is made again from the saved order.
        with self.assertLogs("order_service.services", level="ERROR"):
            again = client.get("/api/orders/1001/bill", headers=as_alice())
        self.assertEqual(again.status_code, 200)
        self.assertEqual(again.get_data(as_text=True), response.get_json()["billHtml"])

    # ------------------------------------------------------------ who may ask (N4, N5)

    def test_without_a_token_every_endpoint_is_401(self):
        for response in [
            self.client.post("/api/orders", json={"items": []}),
            self.client.get("/api/orders"),
            self.client.get("/api/orders/1001/bill"),
            self.client.patch("/api/orders/1001/payment-status", json={"paymentStatus": "PAID"}),
            self.client.get("/api/orders/mine"),
            self.client.post("/api/orders/1001/pay"),
        ]:
            self.assert_error(response, 401, "You are not logged in")

    def test_an_ended_session_is_401(self):
        response = self.client.get("/api/orders", headers={"Authorization": "Bearer old-token"})
        self.assert_error(response, 401, "Your session has ended. Please log in again.")

    def test_when_user_service_is_down_the_answer_is_503_not_a_crash(self):
        self.sessions.down = True
        self.assert_error(self.place((self.clean_code, "BUY")), 503, "The login service is not answering. Please try again in a moment.")

    def test_a_manager_cannot_place_an_order(self):
        self.assert_error(self.place((self.clean_code, "BUY"), headers=as_manager()), 403, "Only a customer can place an order")
        self.assert_nothing_was_ordered()

    # ------------------------------------------------------------ list orders (FR12)

    def test_a_manager_sees_all_orders_newest_first(self):
        self.place((self.clean_code, "BUY"), (self.concurrency, "RENT"))
        self.now = datetime(2026, 11, 14, 18, 40, 0)
        self.place((self.database, "BUY"), headers=as_omar())
        response = self.client.get("/api/orders", headers=as_manager())
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json(), [
            {"id": 1002, "username": "omar", "createdAt": "2026-11-14T18:40:00", "total": 55.0, "paymentStatus": "PENDING"},
            {"id": 1001, "username": "alice", "createdAt": "2026-11-13T10:05:00", "total": 48.0, "paymentStatus": "PENDING"},
        ])

    def test_with_no_orders_the_list_is_empty(self):
        self.assertEqual(self.client.get("/api/orders", headers=as_manager()).get_json(), [])

    def test_a_customer_cannot_list_orders(self):
        self.assert_error(self.client.get("/api/orders", headers=as_alice()), 403, "Only a manager can do this")

    # ------------------------------------------------------------ a customer's own orders (account page, beyond the PRD)

    def test_a_customer_sees_only_their_own_orders_newest_first_with_items(self):
        self.place((self.clean_code, "BUY"))
        self.place((self.database, "BUY"), headers=as_omar())
        self.now = datetime(2026, 11, 14, 18, 40, 0)
        self.place((self.concurrency, "RENT"))
        response = self.client.get("/api/orders/mine", headers=as_alice())
        self.assertEqual(response.status_code, 200)
        orders = response.get_json()
        self.assertEqual([(o["id"], o["username"], o["total"]) for o in orders], [(1003, "alice", 8.0), (1001, "alice", 40.0)])
        self.assertEqual([(i["title"], i["rentDueDate"]) for i in orders[0]["items"]], [("Java Concurrency in Practice", "2026-11-21")])

    def test_a_customer_with_no_orders_gets_an_empty_list(self):
        self.place((self.clean_code, "BUY"), headers=as_omar())
        self.assertEqual(self.client.get("/api/orders/mine", headers=as_alice()).get_json(), [])

    def test_a_manager_has_no_orders_of_their_own(self):
        self.assert_error(self.client.get("/api/orders/mine", headers=as_manager()), 403, "Only a customer can do this")

    # ------------------------------------------------------------ pretend checkout (beyond the PRD)

    def pay(self, order_id, headers=None):
        return self.client.post(f"/api/orders/{order_id}/pay", headers=headers or as_alice())

    def test_a_customer_pays_their_own_order(self):
        self.place((self.clean_code, "BUY"))
        response = self.pay(1001)
        self.assertEqual(response.status_code, 200)
        self.assertEqual((response.get_json()["id"], response.get_json()["paymentStatus"]), (1001, "PAID"))
        self.assertEqual(self.repository.find(1001).payment_status, "PAID")

    def test_paying_an_order_twice_is_409(self):
        self.place((self.clean_code, "BUY"))
        self.pay(1001)
        self.assert_error(self.pay(1001), 409, "This order is already paid")

    def test_a_customer_cannot_pay_someone_elses_order(self):
        self.place((self.clean_code, "BUY"), headers=as_omar())
        self.assert_error(self.pay(1001), 403, "This order belongs to another customer")
        self.assertEqual(self.repository.find(1001).payment_status, "PENDING", "nothing was changed")

    def test_a_manager_marks_payment_instead_of_paying(self):
        self.place((self.clean_code, "BUY"))
        self.assert_error(self.pay(1001, headers=as_manager()), 403, "Only a customer can do this")

    def test_paying_an_unknown_order_is_404(self):
        self.assert_error(self.pay(9999), 404, "This order does not exist")

    # ------------------------------------------------------------ one order as JSON (FR8, FR12)

    def test_a_manager_gets_one_order_with_its_items(self):
        self.place((self.clean_code, "BUY"), (self.concurrency, "RENT"))
        response = self.client.get("/api/orders/1001", headers=as_manager())
        self.assertEqual(response.status_code, 200)
        order = response.get_json()
        self.assertEqual((order["id"], order["username"], order["email"], order["paymentStatus"], order["total"]), (1001, "alice", "alice@example.com", "PENDING", 48.0))
        self.assertEqual([(i["title"], i["type"], i["unitPrice"], i["rentDueDate"]) for i in order["items"]], [("Clean Code", "BUY", 40.0, None), ("Java Concurrency in Practice", "RENT", 8.0, "2026-11-20")])
        self.assertNotIn("billHtml", order)

    def test_the_owner_gets_their_own_order(self):
        self.place((self.clean_code, "BUY"))
        self.assertEqual(self.client.get("/api/orders/1001", headers=as_alice()).status_code, 200)

    def test_a_customer_cannot_get_someone_elses_order(self):
        self.place((self.clean_code, "BUY"))
        self.assert_error(self.client.get("/api/orders/1001", headers=as_omar()), 403, "This order belongs to another customer")

    def test_an_unknown_order_is_404(self):
        self.assert_error(self.client.get("/api/orders/9999", headers=as_manager()), 404, "This order does not exist")

    # ------------------------------------------------------------ the bill (FR8, FR9)

    def test_the_owner_can_open_the_bill(self):
        bill_html = self.place((self.clean_code, "BUY")).get_json()["billHtml"]
        response = self.client.get("/api/orders/1001/bill", headers=as_alice())
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.mimetype, "text/html")
        self.assertEqual(response.get_data(as_text=True), bill_html)

    def test_a_manager_can_open_any_bill(self):
        self.place((self.clean_code, "BUY"))
        response = self.client.get("/api/orders/1001/bill", headers=as_manager())
        self.assertEqual(response.status_code, 200)
        self.assertIn("<strong>Order ID</strong>1001", response.get_data(as_text=True))

    def test_a_customer_cannot_open_someone_elses_bill(self):
        self.place((self.clean_code, "BUY"))
        self.assert_error(self.client.get("/api/orders/1001/bill", headers=as_omar()), 403, "This bill belongs to another customer")

    def test_the_bill_of_an_unknown_order_is_404(self):
        self.assert_error(self.client.get("/api/orders/9999/bill", headers=as_manager()), 404, "This order does not exist")
        self.assert_error(self.client.get("/api/orders/9999/bill", headers=as_alice()), 404, "This order does not exist")

    def test_a_bill_whose_file_was_deleted_is_made_again(self):
        bill_html = self.place((self.clean_code, "BUY")).get_json()["billHtml"]
        (self.bills_folder / "bill-1001.html").unlink()
        response = self.client.get("/api/orders/1001/bill", headers=as_alice())
        self.assertEqual(response.get_data(as_text=True), bill_html)
        self.assertTrue((self.bills_folder / "bill-1001.html").is_file(), "and saved again")

    # ------------------------------------------------------------ payment status (FR13)

    def mark(self, order_id, status, headers=None):
        return self.client.patch(f"/api/orders/{order_id}/payment-status", json={"paymentStatus": status}, headers=headers or as_manager())

    def test_a_manager_marks_an_order_as_paid(self):
        self.place((self.clean_code, "BUY"))
        response = self.mark(1001, "PAID")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json(), {"id": 1001, "username": "alice", "createdAt": "2026-11-13T10:05:00", "total": 40.0, "paymentStatus": "PAID"})
        self.assertEqual(self.client.get("/api/orders", headers=as_manager()).get_json()[0]["paymentStatus"], "PAID")

    def test_a_manager_can_put_an_order_back_to_pending(self):
        self.place((self.clean_code, "BUY"))
        self.mark(1001, "PAID")
        self.assertEqual(self.mark(1001, "PENDING").get_json()["paymentStatus"], "PENDING")

    def test_a_status_other_than_pending_or_paid_is_400(self):
        self.place((self.clean_code, "BUY"))
        self.assert_error(self.mark(1001, "REFUNDED"), 400, "The payment status must be PENDING or PAID")

    def test_a_customer_cannot_change_the_payment_status(self):
        self.place((self.clean_code, "BUY"))
        self.assert_error(self.mark(1001, "PAID", headers=as_alice()), 403, "Only a manager can do this")
        self.assertEqual(self.repository.find(1001).payment_status, "PENDING", "nothing was changed")

    def test_the_payment_status_of_an_unknown_order_is_404(self):
        self.assert_error(self.mark(9999, "PAID"), 404, "This order does not exist")

    # ------------------------------------------------------------ everything else

    def test_an_unknown_address_is_404_and_a_wrong_method_is_405(self):
        self.assert_error(self.client.get("/api/nothing", headers=as_alice()), 404, "There is nothing at this address")
        self.assert_error(self.client.delete("/api/orders", headers=as_manager()), 405, "This address does not accept that kind of request")

    def test_an_order_id_that_is_not_a_number_is_404(self):
        self.assert_error(self.client.get("/api/orders/abc/bill", headers=as_manager()), 404, "There is nothing at this address")


if __name__ == "__main__":
    unittest.main()
