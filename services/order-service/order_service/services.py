"""The rules about orders. Knows nothing about HTTP or SQL."""
import logging
from dataclasses import dataclass, replace
from datetime import datetime, timedelta
from decimal import Decimal
from typing import Callable

from .bill import BillStore, render_bill
from .catalog import BookCatalog
from .errors import ConflictError, ForbiddenError, NotFoundError
from .mailer import Mailer
from .models import PAID, PENDING, RENT, CurrentUser, Order, OrderItem
from .pricing import RENT_DAYS, charge_for
from .repository import OrderRepository
from .schemas import OrderInput

log = logging.getLogger(__name__)

NOT_FOUND = "This order does not exist"


@dataclass(frozen=True)
class PlacedOrder:
    """What placing an order gives back: the saved order, its bill, and whether the bill is being emailed."""

    order: Order
    bill_html: str
    email_queued: bool


class OrderService:
    def __init__(self, orders: OrderRepository, catalog: BookCatalog, bills: BillStore, mailer: Mailer, clock: Callable[[], datetime] = datetime.now):
        self._orders = orders
        self._catalog = catalog
        self._bills = bills
        self._mailer = mailer
        self._clock = clock

    def place(self, user: CurrentUser, order_input: OrderInput) -> PlacedOrder:
        """FR6-FR10: take the copies, save the order, write the bill, email it.

        All or nothing: if a book is missing or sold out, or the order cannot be saved,
        every copy already taken is put back and nothing is saved. Once the order is
        saved it stands; a bill file or an email that fails is logged and can be redone.
        """
        # Whole seconds: that is what the database keeps, and the bill must match it.
        now = self._clock().replace(microsecond=0)
        taken: dict[str, int] = {}
        try:
            # The copies come first. The order is saved only once every book is really ours,
            # so there is never a saved order for a book that had no copies.
            wanted: dict[str, int] = {}
            for line in order_input.lines:
                wanted[line.book_id] = wanted.get(line.book_id, 0) + line.quantity
            books = {}
            for book_id, quantity in wanted.items():
                books[book_id] = self._catalog.take(book_id, quantity)
                taken[book_id] = quantity

            items = tuple(
                OrderItem(
                    book_id=line.book_id,
                    title=books[line.book_id].title,
                    author=books[line.book_id].author,
                    type=line.type,
                    quantity=line.quantity,
                    unit_price=charge_for(books[line.book_id].price, line.type),
                    rent_due_date=now.date() + timedelta(days=RENT_DAYS) if line.type == RENT else None,
                )
                for line in order_input.lines
            )
            total = sum((item.line_total for item in items), Decimal("0.00"))
            order = self._orders.save(Order(None, user.user_id, user.username, user.email, now, PENDING, items, total, None))
        except BaseException:
            self._give_back(taken)
            raise

        bill_html = render_bill(order)
        order = self._save_bill(order, bill_html)
        return PlacedOrder(order, bill_html, self._email(order, bill_html))

    def list_all(self) -> list[Order]:
        """FR12: every order, newest first."""
        return self._orders.list_all()

    def list_for(self, user: CurrentUser) -> list[Order]:
        """The customer's own orders, newest first (account page)."""
        return self._orders.list_for_user(user.user_id)

    def get(self, order_id: int, user: CurrentUser) -> Order:
        """One order with its items. N5: a customer may see only their own; a manager any."""
        order = self._orders.find(order_id)
        if order is None:
            raise NotFoundError(NOT_FOUND)
        if not user.is_manager and order.user_id != user.user_id:
            raise ForbiddenError("This order belongs to another customer")
        return order

    def pay(self, order_id: int, user: CurrentUser) -> Order:
        """The pretend checkout: a customer pays their own pending order. Nothing is charged;
        the order is only marked as paid, as a manager would (FR13)."""
        order = self.get(order_id, user)
        if order.payment_status == PAID:
            raise ConflictError("This order is already paid")
        return self.set_payment_status(order_id, PAID)

    def bill_for(self, order_id: int, user: CurrentUser) -> str:
        """FR8, FR9: the bill of an order. N5: a customer may open only their own; a manager any."""
        order = self._orders.find(order_id)
        if order is None:
            raise NotFoundError(NOT_FOUND)
        if not user.is_manager and order.user_id != user.user_id:
            raise ForbiddenError("This bill belongs to another customer")
        bill_html = self._bills.read(order_id)
        if bill_html is None:
            # The file is missing (deleted, or it could not be written at order time). The
            # bill depends only on the saved order, so it is made again, identical.
            bill_html = render_bill(order)
            self._save_bill(order, bill_html)
        return bill_html

    def set_payment_status(self, order_id: int, payment_status: str) -> Order:
        """FR13: a manager marks an order as paid (or back to pending, to correct a mistake)."""
        updated = self._orders.set_payment_status(order_id, payment_status)
        if updated is None:
            raise NotFoundError(NOT_FOUND)
        return updated

    def _give_back(self, taken: dict[str, int]) -> None:
        for book_id, quantity in taken.items():
            try:
                self._catalog.give_back(book_id, quantity)
            except Exception:  # noqa: BLE001 - keep giving back the others; the first error is the one reported
                log.exception("Could not give back %s of book %s: its number of copies is now too low", quantity, book_id)

    def _save_bill(self, order: Order, bill_html: str) -> Order:
        """Write the bill file and record its name. A failure is logged, not raised: the order stands."""
        try:
            bill_file = self._bills.write(order.id, bill_html)
            self._orders.set_bill_file(order.id, bill_file)
            return replace(order, bill_file=bill_file)
        except Exception:  # noqa: BLE001
            log.exception("Could not save the bill of order %s; it will be made again when it is opened", order.id)
            return order

    def _email(self, order: Order, bill_html: str) -> bool:
        try:
            return self._mailer.send_bill(order, bill_html)
        except Exception:  # noqa: BLE001 - a failed email does not fail the order (architecture decision 6)
            log.exception("Could not email the bill of order %s", order.id)
            return False
