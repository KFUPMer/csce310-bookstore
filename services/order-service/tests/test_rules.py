"""The rules that need no HTTP: what a book costs, and what a request must contain."""
import unittest
from decimal import Decimal

from order_service.config import Config
from order_service.errors import ValidationError
from order_service.pricing import RENT_DAYS, RENT_RATE, charge_for
from order_service.schemas import MAX_ITEMS, OrderInput, PaymentStatusInput

BOOK_A = "a" * 24
BOOK_B = "b" * 24


class ChargeTest(unittest.TestCase):
    def test_the_renting_rule_is_ten_percent_for_seven_days(self):
        self.assertEqual(RENT_RATE, Decimal("0.10"))
        self.assertEqual(RENT_DAYS, 7)

    def test_buying_costs_the_book_price(self):
        self.assertEqual(charge_for(Decimal("40.00"), "BUY"), Decimal("40.00"))

    def test_renting_costs_ten_percent_of_the_price(self):
        self.assertEqual(charge_for(Decimal("80.00"), "RENT"), Decimal("8.00"))

    def test_a_rent_charge_is_rounded_to_cents_half_up(self):
        self.assertEqual(charge_for(Decimal("35.55"), "RENT"), Decimal("3.56"))
        self.assertEqual(charge_for(Decimal("35.54"), "RENT"), Decimal("3.55"))
        self.assertEqual(charge_for(Decimal("0.01"), "RENT"), Decimal("0.00"))


class OrderInputTest(unittest.TestCase):
    def assert_rejected(self, body, message):
        with self.assertRaises(ValidationError) as raised:
            OrderInput.from_json(body)
        self.assertEqual(raised.exception.message, message)

    def test_reads_each_selected_book(self):
        order = OrderInput.from_json({"items": [{"bookId": BOOK_A, "type": "BUY"}, {"bookId": BOOK_B, "type": "RENT"}]})
        self.assertEqual([(line.book_id, line.type, line.quantity) for line in order.lines], [(BOOK_A, "BUY", 1), (BOOK_B, "RENT", 1)])

    def test_the_same_book_chosen_twice_becomes_one_line_with_quantity_two(self):
        order = OrderInput.from_json({"items": [{"bookId": BOOK_A, "type": "BUY"}, {"bookId": BOOK_A, "type": "BUY"}]})
        self.assertEqual([(line.book_id, line.type, line.quantity) for line in order.lines], [(BOOK_A, "BUY", 2)])

    def test_buying_and_renting_the_same_book_stay_two_lines(self):
        order = OrderInput.from_json({"items": [{"bookId": BOOK_A, "type": "BUY"}, {"bookId": BOOK_A, "type": "RENT"}]})
        self.assertEqual([(line.type, line.quantity) for line in order.lines], [("BUY", 1), ("RENT", 1)])

    def test_a_book_id_is_stored_in_lower_case(self):
        order = OrderInput.from_json({"items": [{"bookId": "A" * 24, "type": "BUY"}]})
        self.assertEqual(order.lines[0].book_id, BOOK_A)

    def test_the_body_must_be_an_object_with_items(self):
        self.assert_rejected([], "Send the order as a JSON object")
        self.assert_rejected({}, "Select at least one book")
        self.assert_rejected({"items": []}, "Select at least one book")
        self.assert_rejected({"items": "all"}, "Select at least one book")

    def test_an_order_has_a_largest_size(self):
        too_many = [{"bookId": BOOK_A, "type": "BUY"}] * (MAX_ITEMS + 1)
        self.assert_rejected({"items": too_many}, f"An order can have at most {MAX_ITEMS} books")

    def test_each_item_needs_a_real_book_id(self):
        for bad in [None, 12, "", "abc", "g" * 24, "a" * 25, "../../api/books"]:
            self.assert_rejected({"items": [{"bookId": bad, "type": "BUY"}]}, "Item 1: the book id is not valid")

    def test_each_item_is_bought_or_rented(self):
        for bad in [None, "", "buy", "STEAL", 1]:
            self.assert_rejected({"items": [{"bookId": BOOK_A, "type": "BUY"}, {"bookId": BOOK_B, "type": bad}]}, "Item 2: choose BUY or RENT")

    def test_an_item_must_be_an_object(self):
        self.assert_rejected({"items": ["x"]}, "Item 1: the book id is not valid")


class PaymentStatusInputTest(unittest.TestCase):
    def test_accepts_pending_and_paid(self):
        self.assertEqual(PaymentStatusInput.from_json({"paymentStatus": "PAID"}).payment_status, "PAID")
        self.assertEqual(PaymentStatusInput.from_json({"paymentStatus": "PENDING"}).payment_status, "PENDING")

    def test_rejects_anything_else(self):
        for body in [{}, {"paymentStatus": "paid"}, {"paymentStatus": "REFUNDED"}, {"paymentStatus": 1}, "PAID"]:
            with self.assertRaises(ValidationError) as raised:
                PaymentStatusInput.from_json(body)
            self.assertEqual(raised.exception.message, "The payment status must be PENDING or PAID")


class ConfigTest(unittest.TestCase):
    def test_a_port_that_is_not_a_number_is_named_in_the_error(self):
        from unittest import mock

        with mock.patch.dict("os.environ", {"ORDER_SERVICE_PORT": "80 83"}):
            with self.assertRaises(ValueError) as raised:
                Config.load()
        self.assertEqual(str(raised.exception), "The setting ORDER_SERVICE_PORT must be a whole number")

    def test_printing_the_settings_never_shows_a_secret(self):
        from unittest import mock

        secrets = {"MYSQL_PASSWORD": "db-secret-1", "SERVICE_KEY": "key-secret-2", "SMTP_PASSWORD": "mail-secret-3"}
        with mock.patch.dict("os.environ", secrets):
            shown = repr(Config.load())
        for secret in secrets.values():
            self.assertNotIn(secret, shown)


if __name__ == "__main__":
    unittest.main()
