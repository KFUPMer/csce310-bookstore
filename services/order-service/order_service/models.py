"""Plain data.

Money is kept as `Decimal`, never `float`, so that sums of prices are exact.
It becomes a JSON number only at the last moment, in `to_json`.
"""
from dataclasses import dataclass
from datetime import date, datetime
from decimal import Decimal
from typing import Optional

BUY = "BUY"
RENT = "RENT"
ITEM_TYPES = (BUY, RENT)

PENDING = "PENDING"
PAID = "PAID"
PAYMENT_STATUSES = (PENDING, PAID)


@dataclass(frozen=True)
class CurrentUser:
    """Who is making the request, as told by user-service."""

    user_id: int
    username: str
    email: str
    role: str

    @property
    def is_manager(self) -> bool:
        return self.role == "MANAGER"

    @property
    def is_customer(self) -> bool:
        return self.role == "CUSTOMER"


@dataclass(frozen=True)
class CatalogBook:
    """What order-service needs to know about a book, as told by book-service."""

    id: str
    title: str
    author: str
    price: Decimal


@dataclass(frozen=True)
class OrderItem:
    """One line of an order. Title, author, and price are copied from the book at order
    time, so the order and its bill stay correct if the book is changed later."""

    book_id: str
    title: str
    author: str
    type: str
    quantity: int
    unit_price: Decimal
    """What was charged for one copy: the price for BUY, 10% of it for RENT."""
    rent_due_date: Optional[date]
    """When a rented book is due back. None for a bought book."""

    @property
    def line_total(self) -> Decimal:
        return self.unit_price * self.quantity

    def to_json(self) -> dict:
        return {
            "title": self.title,
            "author": self.author,
            "type": self.type,
            "quantity": self.quantity,
            "unitPrice": float(self.unit_price),
            "rentDueDate": self.rent_due_date.isoformat() if self.rent_due_date else None,
        }


@dataclass(frozen=True)
class Order:
    """An order with its items. `id` is None until the order has been saved."""

    id: Optional[int]
    user_id: int
    username: str
    email: str
    created_at: datetime
    payment_status: str
    items: tuple[OrderItem, ...]
    total: Decimal
    bill_file: Optional[str]
    """Where the bill was saved, e.g. bills/bill-1042.html. None if it has not been written."""

    def to_summary_json(self) -> dict:
        """One row of the manager's list (FR12)."""
        return {
            "id": self.id,
            "username": self.username,
            "createdAt": self.created_at.isoformat(),
            "total": float(self.total),
            "paymentStatus": self.payment_status,
        }

    def to_json(self) -> dict:
        """The whole order: returned when it is placed, and by GET /api/orders/{id}."""
        return {
            "id": self.id,
            "username": self.username,
            "email": self.email,
            "createdAt": self.created_at.isoformat(),
            "paymentStatus": self.payment_status,
            "items": [item.to_json() for item in self.items],
            "total": float(self.total),
            "billFile": self.bill_file,
        }
