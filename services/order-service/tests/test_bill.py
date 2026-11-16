"""The bill: what is on it (FR8), and saving it as an HTML file (FR9)."""
import tempfile
import unittest
from datetime import date, datetime
from decimal import Decimal
from pathlib import Path

from order_service.bill import BillStore, bill_file_name, render_bill
from order_service.models import Order, OrderItem

ORDER = Order(
    id=1042,
    user_id=1,
    username="alice",
    email="alice@example.com",
    created_at=datetime(2026, 11, 3, 9, 5, 0),
    payment_status="PENDING",
    items=(
        OrderItem("a" * 24, "Clean Code", "Robert C. Martin", "BUY", 2, Decimal("40.00"), None),
        OrderItem("b" * 24, "Java Concurrency in Practice", "Brian Goetz", "RENT", 1, Decimal("8.00"), date(2026, 11, 10)),
    ),
    total=Decimal("88.00"),
    bill_file=None,
)


class RenderBillTest(unittest.TestCase):
    def setUp(self):
        self.html = render_bill(ORDER)

    def test_shows_the_order_id_date_and_customer(self):
        self.assertIn("<title>Bill — Order 1042</title>", self.html)
        self.assertIn("<strong>Order ID</strong>1042", self.html)
        self.assertIn("<strong>Date</strong>3 November 2026, 09:05", self.html)
        self.assertIn("<strong>Customer</strong>alice<br>alice@example.com", self.html)

    def test_shows_each_item_with_its_price(self):
        self.assertIn('<tr><td>Clean Code<div class="author">Robert C. Martin</div></td><td>Buy</td><td>—</td><td class="num">2</td><td class="num">$80.00</td></tr>', self.html)
        self.assertIn('<td>Rent (7 days)</td><td>10 November 2026</td><td class="num">1</td><td class="num">$8.00</td></tr>', self.html)

    def test_shows_the_total_amount_due(self):
        self.assertIn('Total amount due</td><td class="num">$88.00</td>', self.html)

    def test_always_says_pending_even_for_a_paid_order(self):
        from dataclasses import replace

        self.assertIn("Payment status: <span>Pending</span>", render_bill(replace(ORDER, payment_status="PAID")))

    def test_is_one_self_contained_file(self):
        self.assertTrue(self.html.startswith("<!DOCTYPE html>"))
        for outside in ["<script", "<img", "<link", "http://", "https://"]:
            self.assertNotIn(outside, self.html)

    def test_text_from_a_book_or_a_user_cannot_become_html(self):
        from dataclasses import replace

        nasty = OrderItem("c" * 24, "<script>alert(1)</script>", 'A & "B"', "BUY", 1, Decimal("1.00"), None)
        html = render_bill(replace(ORDER, username="<b>eve</b>", items=(nasty,)))
        self.assertNotIn("<script>", html)
        self.assertNotIn("<b>eve</b>", html)
        self.assertIn("&lt;script&gt;alert(1)&lt;/script&gt;", html)
        self.assertIn("A &amp; &quot;B&quot;", html)

    def test_large_amounts_have_thousands_separators(self):
        from dataclasses import replace

        self.assertIn("$12,345.60", render_bill(replace(ORDER, total=Decimal("12345.60"))))


class BillStoreTest(unittest.TestCase):
    def setUp(self):
        self.folder = tempfile.TemporaryDirectory()
        self.addCleanup(self.folder.cleanup)
        self.bills = BillStore(Path(self.folder.name) / "bills")

    def test_the_file_is_named_after_the_order(self):
        self.assertEqual(bill_file_name(1042), "bills/bill-1042.html")

    def test_write_saves_the_html_file_and_returns_its_name(self):
        name = self.bills.write(1042, "<p>héllo — bill</p>")
        self.assertEqual(name, "bills/bill-1042.html")
        saved = Path(self.folder.name) / "bills" / "bill-1042.html"
        self.assertEqual(saved.read_text(encoding="utf-8"), "<p>héllo — bill</p>")

    def test_read_returns_what_was_written(self):
        self.bills.write(7, "<p>seven</p>")
        self.assertEqual(self.bills.read(7), "<p>seven</p>")

    def test_writing_again_replaces_the_bill_and_leaves_no_other_file(self):
        # (That a reader never sees half a bill comes from writing a draft and swapping it in;
        # this test checks the swap leaves the new text and no draft behind, not the timing.)
        self.bills.write(7, "<p>first, and much longer</p>")
        self.bills.write(7, "<p>second</p>")
        self.assertEqual(self.bills.read(7), "<p>second</p>")
        self.assertEqual([path.name for path in (Path(self.folder.name) / "bills").iterdir()], ["bill-7.html"])

    def test_the_bill_text_states_the_renting_rule_from_the_one_place_it_is_defined(self):
        from unittest import mock

        with mock.patch("order_service.bill.RENT_DAYS", 14), mock.patch("order_service.bill.RENT_RATE", Decimal("0.25")):
            html = render_bill(ORDER)
        self.assertIn("Rent (14 days)", html)
        self.assertIn("charged at 25% of the book price and are due back 14 days after", html)

    def test_read_a_bill_that_was_never_written_is_none(self):
        self.assertIsNone(self.bills.read(8))


if __name__ == "__main__":
    unittest.main()
