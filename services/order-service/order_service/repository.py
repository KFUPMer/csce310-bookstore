"""Reads and writes orders.

`OrderRepository` says what the rules need from storage. `MySqlOrderRepository`
is the real one. `InMemoryOrderRepository` is for tests, so the rules can be
tested without a database.
"""
from abc import ABC, abstractmethod
from contextlib import contextmanager
from dataclasses import replace
from typing import Optional

import mysql.connector
from mysql.connector.pooling import MySQLConnectionPool

from .config import Config
from .models import Order, OrderItem

# As many connections as the server has request threads (__main__.py), so a request never
# finds the pool empty. Opened once at start-up: a new connection costs about 35 ms (P-005).
POOL_SIZE = 8

FIRST_ORDER_ID = 1001  # the same starting number as the orders table


class OrderRepository(ABC):
    @abstractmethod
    def save(self, order: Order) -> Order:
        """Store a new order with all its items, or nothing at all. Returns it with its id."""

    @abstractmethod
    def find(self, order_id: int) -> Optional[Order]:
        """The order with this id, or None."""

    @abstractmethod
    def list_all(self) -> list[Order]:
        """Every order, newest first."""

    @abstractmethod
    def set_payment_status(self, order_id: int, payment_status: str) -> Optional[Order]:
        """Change an order's payment status. Returns the updated order, or None if it does not exist."""

    @abstractmethod
    def set_bill_file(self, order_id: int, bill_file: str) -> None:
        """Record where the order's bill was saved."""


def create_pool(config: Config) -> MySQLConnectionPool:
    """Open the connections to MySQL. Raises mysql.connector.Error if it cannot be reached."""
    return MySQLConnectionPool(
        pool_name="orders",
        pool_size=POOL_SIZE,
        host=config.mysql_host,
        user=config.mysql_user,
        password=config.mysql_password,
        database=config.mysql_database,
        connection_timeout=3,  # if MySQL is down, fail in 3 seconds instead of hanging
    )


_ORDER_COLUMNS = "o.id, o.user_id, u.username, u.email, o.created_at, o.payment_status, o.total, o.bill_file"
_ITEM_COLUMNS = "order_id, book_id, title, author, type, quantity, unit_price, rent_due_date"


class MySqlOrderRepository(OrderRepository):
    """Orders in the MySQL tables `orders` and `order_items`. The customer's name and email
    are read from `users`, so an order always shows the account as it is now.

    Every value goes to MySQL as a parameter (%s), never as part of the SQL text.
    """

    def __init__(self, pool: MySQLConnectionPool):
        self._pool = pool

    @contextmanager
    def _transaction(self):
        """Lend a connection: commit if the block succeeds, undo everything if it fails."""
        connection = self._pool.get_connection()
        try:
            yield connection
            connection.commit()
        except BaseException:
            try:
                connection.rollback()
            except mysql.connector.Error:
                pass  # the connection itself is gone; the original error is the one to report
            raise
        finally:
            connection.close()  # gives it back to the pool

    def save(self, order: Order) -> Order:
        with self._transaction() as connection:
            cursor = connection.cursor()
            cursor.execute(
                "INSERT INTO orders (user_id, payment_status, total, created_at) VALUES (%s, %s, %s, %s)",
                (order.user_id, order.payment_status, order.total, order.created_at),
            )
            order_id = cursor.lastrowid
            cursor.executemany(
                f"INSERT INTO order_items ({_ITEM_COLUMNS}) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)",
                [(order_id, i.book_id, i.title, i.author, i.type, i.quantity, i.unit_price, i.rent_due_date) for i in order.items],
            )
            cursor.close()
            return self._find(connection, order_id)

    def find(self, order_id: int) -> Optional[Order]:
        with self._transaction() as connection:
            return self._find(connection, order_id)

    def list_all(self) -> list[Order]:
        with self._transaction() as connection:
            cursor = connection.cursor()
            cursor.execute(f"SELECT {_ORDER_COLUMNS} FROM orders o JOIN users u ON u.id = o.user_id ORDER BY o.created_at DESC, o.id DESC")
            orders = cursor.fetchall()
            # Two queries for the whole list, however many orders there are.
            cursor.execute(f"SELECT {_ITEM_COLUMNS} FROM order_items ORDER BY id")
            items: dict[int, list[OrderItem]] = {}
            for row in cursor.fetchall():
                items.setdefault(row[0], []).append(self._to_item(row))
            cursor.close()
            return [self._to_order(row, items.get(row[0], [])) for row in orders]

    def set_payment_status(self, order_id: int, payment_status: str) -> Optional[Order]:
        with self._transaction() as connection:
            cursor = connection.cursor()
            cursor.execute("UPDATE orders SET payment_status = %s WHERE id = %s", (payment_status, order_id))
            cursor.close()
            # Not decided by "rows changed": setting the status an order already has changes no row.
            return self._find(connection, order_id)

    def set_bill_file(self, order_id: int, bill_file: str) -> None:
        with self._transaction() as connection:
            cursor = connection.cursor()
            cursor.execute("UPDATE orders SET bill_file = %s WHERE id = %s", (bill_file, order_id))
            cursor.close()

    def _find(self, connection, order_id: int) -> Optional[Order]:
        cursor = connection.cursor()
        cursor.execute(f"SELECT {_ORDER_COLUMNS} FROM orders o JOIN users u ON u.id = o.user_id WHERE o.id = %s", (order_id,))
        row = cursor.fetchone()
        if row is None:
            cursor.close()
            return None
        cursor.execute(f"SELECT {_ITEM_COLUMNS} FROM order_items WHERE order_id = %s ORDER BY id", (order_id,))
        items = [self._to_item(item) for item in cursor.fetchall()]
        cursor.close()
        return self._to_order(row, items)

    @staticmethod
    def _to_order(row: tuple, items: list[OrderItem]) -> Order:
        order_id, user_id, username, email, created_at, payment_status, total, bill_file = row
        return Order(order_id, user_id, username, email, created_at, payment_status, tuple(items), total, bill_file)

    @staticmethod
    def _to_item(row: tuple) -> OrderItem:
        _order_id, book_id, title, author, kind, quantity, unit_price, rent_due_date = row
        return OrderItem(book_id, title, author, kind, quantity, unit_price, rent_due_date)


class InMemoryOrderRepository(OrderRepository):
    """Orders kept in memory, for tests. Behaves like the MySQL one."""

    def __init__(self):
        self._orders: dict[int, Order] = {}
        self._next_id = FIRST_ORDER_ID

    def save(self, order: Order) -> Order:
        saved = replace(order, id=self._next_id)
        self._orders[saved.id] = saved
        self._next_id += 1
        return saved

    def find(self, order_id: int) -> Optional[Order]:
        return self._orders.get(order_id)

    def list_all(self) -> list[Order]:
        return sorted(self._orders.values(), key=lambda order: (order.created_at, order.id), reverse=True)

    def set_payment_status(self, order_id: int, payment_status: str) -> Optional[Order]:
        if order_id not in self._orders:
            return None
        self._orders[order_id] = replace(self._orders[order_id], payment_status=payment_status)
        return self._orders[order_id]

    def set_bill_file(self, order_id: int, bill_file: str) -> None:
        if order_id in self._orders:
            self._orders[order_id] = replace(self._orders[order_id], bill_file=bill_file)
