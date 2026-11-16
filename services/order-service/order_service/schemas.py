"""What a request body must contain. Checked before anything else runs."""
import re
from dataclasses import dataclass
from typing import Any

from .errors import ValidationError
from .models import ITEM_TYPES, PAYMENT_STATUSES

MAX_ITEMS = 50

# A MongoDB id: exactly 24 hexadecimal characters. Checking the shape here also means a
# book id can be put into the address of a call to book-service without any risk.
_BOOK_ID = re.compile(r"[0-9a-f]{24}")


@dataclass(frozen=True)
class OrderLine:
    """One book of the order, bought or rented, and how many copies."""

    book_id: str
    type: str
    quantity: int


@dataclass(frozen=True)
class OrderInput:
    """The body of POST /api/orders (FR6): the selected books."""

    lines: tuple[OrderLine, ...]

    @staticmethod
    def from_json(body: Any) -> "OrderInput":
        """Read and check an order. Raises ValidationError naming the first item that is wrong.

        The same book chosen twice with the same type becomes one line with quantity 2.
        """
        if not isinstance(body, dict):
            raise ValidationError("Send the order as a JSON object")
        items = body.get("items")
        if not isinstance(items, list) or not items:
            raise ValidationError("Select at least one book")
        if len(items) > MAX_ITEMS:
            raise ValidationError(f"An order can have at most {MAX_ITEMS} books")

        quantities: dict[tuple[str, str], int] = {}  # keeps the order the books were chosen in
        for number, item in enumerate(items, start=1):
            book_id = item.get("bookId") if isinstance(item, dict) else None
            if not isinstance(book_id, str) or not _BOOK_ID.fullmatch(book_id.lower()):
                raise ValidationError(f"Item {number}: the book id is not valid")
            kind = item.get("type")
            if kind not in ITEM_TYPES:
                raise ValidationError(f"Item {number}: choose BUY or RENT")
            key = (book_id.lower(), kind)
            quantities[key] = quantities.get(key, 0) + 1

        return OrderInput(tuple(OrderLine(book_id, kind, quantity) for (book_id, kind), quantity in quantities.items()))


@dataclass(frozen=True)
class PaymentStatusInput:
    """The body of PATCH /api/orders/{id}/payment-status (FR13)."""

    payment_status: str

    @staticmethod
    def from_json(body: Any) -> "PaymentStatusInput":
        status = body.get("paymentStatus") if isinstance(body, dict) else None
        if not isinstance(status, str) or status not in PAYMENT_STATUSES:
            raise ValidationError("The payment status must be PENDING or PAID")
        return PaymentStatusInput(status)
