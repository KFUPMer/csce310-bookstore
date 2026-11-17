"""The MySQL repository against the real MySQL.

The services' account may only read and write the `bookstore` database, so
there is no separate test database. Instead every test works on orders of its
own temporary user (`order_repo_test`), and that user and its orders are
deleted afterwards. Other users' orders are never touched. Skipped if MySQL is
not reachable with the settings in services/.env.
"""
import secrets
import unittest
from dataclasses import replace
from datetime import date, datetime
from decimal import Decimal

import bcrypt
import mysql.connector

from order_service.config import Config
from order_service.models import Order, OrderItem
from order_service.repository import MySqlOrderRepository, create_pool

TEST_USER = "order_repo_test"
TEST_EMAIL = "order_repo_test@example.com"
CONFIG = Config.load()


def connect():
    return mysql.connector.connect(
        host=CONFIG.mysql_host, user=CONFIG.mysql_user, password=CONFIG.mysql_password, database=CONFIG.mysql_database, connection_timeout=3
    )


def mysql_is_reachable() -> bool:
    try:
        connect().close()
        return True
    except mysql.connector.Error:
        return False


def remove_test_user(connection) -> None:
    cursor = connection.cursor()
    cursor.execute("DELETE o FROM orders o JOIN users u ON u.id = o.user_id WHERE u.username = %s", (TEST_USER,))
    cursor.execute("DELETE FROM users WHERE username = %s", (TEST_USER,))
    connection.commit()
    cursor.close()


@unittest.skipUnless(mysql_is_reachable(), "MySQL is not reachable")
class MySqlOrderRepositoryTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.connection = connect()
        remove_test_user(cls.connection)  # left over from a run that was interrupted
        # A real hash of a password nobody knows: the account exists but cannot be logged in to.
        unknown_password = bcrypt.hashpw(secrets.token_bytes(24), bcrypt.gensalt(rounds=4, prefix=b"2a")).decode()
        cursor = cls.connection.cursor()
        cursor.execute("INSERT INTO users (username, email, password_hash, role) VALUES (%s, %s, %s, 'CUSTOMER')", (TEST_USER, TEST_EMAIL, unknown_password))
        cls.user_id = cursor.lastrowid
        cls.connection.commit()
        cursor.close()
        cls.orders = MySqlOrderRepository(create_pool(CONFIG))

    @classmethod
    def tearDownClass(cls):
        remove_test_user(cls.connection)
        cls.connection.close()

    def setUp(self):
        cursor = self.connection.cursor()
        cursor.execute("DELETE FROM orders WHERE user_id = %s", (self.user_id,))
        self.connection.commit()
        cursor.close()

    def new_order(self, created_at=datetime(2026, 11, 13, 10, 5, 0), items=None) -> Order:
        items = items or (
            OrderItem("a" * 24, "Clean Code", "Robert C. Martin", "BUY", 2, Decimal("40.00"), None),
            OrderItem("b" * 24, "Java Concurrency in Practice", "Brian Goetz", "RENT", 1, Decimal("8.00"), date(2026, 11, 20)),
        )
        total = sum((item.unit_price * item.quantity for item in items), Decimal("0.00"))
        # The username and email given here are deliberately wrong: the saved order must show the real ones.
        return Order(None, self.user_id, "someone", "someone@example.com", created_at, "PENDING", tuple(items), total, None)

    def count(self, sql: str) -> int:
        cursor = self.connection.cursor()
        cursor.execute(sql, (self.user_id,))
        (number,) = cursor.fetchone()
        self.connection.commit()  # end the read, so the next count sees new rows
        cursor.close()
        return number

    def test_save_gives_the_order_an_id_and_find_returns_all_of_it(self):
        saved = self.orders.save(self.new_order())
        self.assertGreaterEqual(saved.id, 1001)
        found = self.orders.find(saved.id)
        self.assertEqual(found, replace(self.new_order(), id=saved.id, username=TEST_USER, email=TEST_EMAIL))
        self.assertEqual(found.total, Decimal("88.00"))
        self.assertEqual(found.items[1].rent_due_date, date(2026, 11, 20))

    def test_find_an_unknown_order_is_none(self):
        self.assertIsNone(self.orders.find(2_000_000_000))

    def test_an_order_is_saved_whole_or_not_at_all(self):
        # The second item breaks a rule of the table (a RENT with no due date), so the insert fails half-way.
        broken = (
            OrderItem("a" * 24, "Clean Code", "Robert C. Martin", "BUY", 1, Decimal("40.00"), None),
            OrderItem("b" * 24, "No Due Date", "Nobody", "RENT", 1, Decimal("8.00"), None),
        )
        with self.assertRaises(mysql.connector.Error):
            self.orders.save(self.new_order(items=broken))
        self.assertEqual(self.count("SELECT COUNT(*) FROM orders WHERE user_id = %s"), 0)

    def test_list_all_is_newest_first_with_items(self):
        older = self.orders.save(self.new_order(datetime(2026, 11, 12, 18, 40, 0)))
        newer = self.orders.save(self.new_order(datetime(2026, 11, 13, 10, 5, 0)))
        mine = [order for order in self.orders.list_all() if order.user_id == self.user_id]
        self.assertEqual([order.id for order in mine], [newer.id, older.id])
        self.assertEqual([item.title for item in mine[0].items], ["Clean Code", "Java Concurrency in Practice"])

    def test_list_for_user_is_only_that_users_orders_newest_first_with_items(self):
        older = self.orders.save(self.new_order(datetime(2026, 11, 12, 18, 40, 0)))
        newer = self.orders.save(self.new_order(datetime(2026, 11, 13, 10, 5, 0)))
        mine = self.orders.list_for_user(self.user_id)
        self.assertEqual([order.id for order in mine], [newer.id, older.id])
        self.assertEqual([item.title for item in mine[1].items], ["Clean Code", "Java Concurrency in Practice"])
        self.assertEqual(self.orders.list_for_user(-1), [])

    def test_set_payment_status_changes_it_and_returns_the_order(self):
        saved = self.orders.save(self.new_order())
        self.assertEqual(self.orders.set_payment_status(saved.id, "PAID").payment_status, "PAID")
        self.assertEqual(self.orders.find(saved.id).payment_status, "PAID")
        # Setting the status it already has is not "order not found".
        self.assertEqual(self.orders.set_payment_status(saved.id, "PAID").payment_status, "PAID")

    def test_set_payment_status_of_an_unknown_order_is_none(self):
        self.assertIsNone(self.orders.set_payment_status(2_000_000_000, "PAID"))

    def test_set_bill_file_records_where_the_bill_is(self):
        saved = self.orders.save(self.new_order())
        self.assertIsNone(self.orders.find(saved.id).bill_file)
        self.orders.set_bill_file(saved.id, f"bills/bill-{saved.id}.html")
        self.assertEqual(self.orders.find(saved.id).bill_file, f"bills/bill-{saved.id}.html")

    def test_a_connection_is_returned_to_the_pool_after_every_call(self):
        saved = self.orders.save(self.new_order())
        for _ in range(40):  # far more calls than the pool has connections
            self.orders.find(saved.id)
            self.orders.find(2_000_000_000)


if __name__ == "__main__":
    unittest.main()
