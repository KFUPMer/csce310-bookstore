"""What a request body must contain. Checked before anything else runs."""
import re
from dataclasses import dataclass
from datetime import date
from typing import Any, Mapping, Optional

from .errors import ValidationError
from .models import ITEM_TYPES, PAYMENT_STATUSES

MAX_ITEMS = 50

DEFAULT_TOP = 10
MAX_TOP = 50
DATE_FORMAT = "Enter the dates as YYYY-MM-DD"
_DAY = re.compile(r"[0-9]{4}-[0-9]{2}-[0-9]{2}")
_WHOLE_NUMBER = re.compile(r"[0-9]{1,3}")

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
class SalesReportQuery:
    """The query of GET /api/reports/sales: an optional period (inclusive dates) and how many best sellers to list."""

    start: Optional[date]
    end: Optional[date]
    top: int

    @staticmethod
    def from_args(args: Mapping[str, str]) -> "SalesReportQuery":
        """Read and check the query string. A parameter that is left out has its default;
        one that is present but empty is wrong, like any other value that is not allowed."""
        start = _day(args.get("from"))
        end = _day(args.get("to"))
        if start and end and start > end:
            raise ValidationError("The start date must be on or before the end date")
        top = args.get("top")
        if top is None:
            return SalesReportQuery(start, end, DEFAULT_TOP)
        if not _WHOLE_NUMBER.fullmatch(top) or not 1 <= int(top) <= MAX_TOP:
            raise ValidationError(f"top must be a whole number from 1 to {MAX_TOP}")
        return SalesReportQuery(start, end, int(top))


def _day(text: Optional[str]) -> Optional[date]:
    if text is None:
        return None
    # The pattern first: date.fromisoformat alone would also take forms such as 20261118.
    if not _DAY.fullmatch(text):
        raise ValidationError(DATE_FORMAT)
    try:
        return date.fromisoformat(text)
    except ValueError as error:  # the right shape, but no such day, e.g. 2026-02-30
        raise ValidationError(DATE_FORMAT) from error


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
