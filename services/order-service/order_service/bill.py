"""The bill: making it (FR8) and saving it as an HTML file (FR9).

The layout is the approved sample, docs/02-design/bill/bill-sample.html. A
bill is one self-contained file: its styles are inside it and it has no
images or scripts, so it opens and prints anywhere and can be the body of an
email.

A bill depends only on the saved order, and always says "Pending" (it shows
the moment the order was placed; the current status lives in the database).
So the same order always gives the same bill, and a lost file can be made
again.
"""
import os
import threading
from datetime import date, datetime
from decimal import Decimal
from html import escape
from pathlib import Path
from typing import Optional

from .models import RENT, Order, OrderItem
from .pricing import RENT_DAYS, RENT_RATE

BILLS_FOLDER = "bills"

# Written out, so the bill is in English whatever language Windows is set to.
_MONTHS = ("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December")

_STYLE = """
  body { font-family: Georgia, "Times New Roman", serif; color: #111; max-width: 720px; margin: 40px auto; padding: 0 24px; }
  header { display: flex; justify-content: space-between; align-items: flex-end; border-bottom: 2px solid #111; padding-bottom: 12px; }
  h1 { font-size: 26px; margin: 0; letter-spacing: 0.5px; }
  .doc { font-size: 14px; text-transform: uppercase; letter-spacing: 2px; }
  .meta { display: flex; justify-content: space-between; margin: 24px 0; font-size: 14px; line-height: 1.6; }
  .meta strong { display: block; font-size: 11px; text-transform: uppercase; letter-spacing: 1px; color: #555; font-weight: normal; }
  table { width: 100%; border-collapse: collapse; font-size: 14px; }
  th { text-align: left; font-size: 11px; text-transform: uppercase; letter-spacing: 1px; color: #555; font-weight: normal; border-bottom: 1px solid #111; padding: 8px 6px; }
  td { padding: 10px 6px; border-bottom: 1px solid #ccc; vertical-align: top; }
  .num { text-align: right; white-space: nowrap; }
  .author { color: #555; font-size: 13px; }
  tfoot td { border-bottom: none; font-size: 16px; font-weight: bold; padding-top: 16px; }
  .status { margin-top: 24px; font-size: 14px; }
  .status span { border: 1px solid #111; padding: 3px 10px; text-transform: uppercase; letter-spacing: 1px; font-size: 12px; }
  footer { margin-top: 40px; padding-top: 12px; border-top: 1px solid #ccc; font-size: 12px; color: #555; line-height: 1.5; }
  @media print { body { margin: 0 auto; } }
"""


def money(amount: Decimal) -> str:
    """An amount as it is printed: $1,234.50."""
    return f"${amount:,.2f}"


def _day(value: date) -> str:
    return f"{value.day} {_MONTHS[value.month - 1]} {value.year}"


def _moment(value: datetime) -> str:
    return f"{_day(value)}, {value:%H:%M}"


def _row(item: OrderItem) -> str:
    # escape(): a title or author is text typed by a manager. It must appear as text, never run as HTML.
    rented = item.type == RENT
    return (
        f'      <tr><td>{escape(item.title)}<div class="author">{escape(item.author)}</div></td>'
        f'<td>{f"Rent ({RENT_DAYS} days)" if rented else "Buy"}</td>'
        f'<td>{_day(item.rent_due_date) if rented and item.rent_due_date else "—"}</td>'
        f'<td class="num">{item.quantity}</td><td class="num">{money(item.line_total)}</td></tr>'
    )


def render_bill(order: Order) -> str:
    """The bill of a saved order, as one HTML document."""
    rows = "\n".join(_row(item) for item in order.items)
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Bill — Order {order.id}</title>
<style>{_STYLE}</style>
</head>
<body>
  <header>
    <h1>Bookstore</h1>
    <div class="doc">Bill</div>
  </header>

  <div class="meta">
    <div><strong>Order ID</strong>{order.id}</div>
    <div><strong>Date</strong>{_moment(order.created_at)}</div>
    <div><strong>Customer</strong>{escape(order.username)}<br>{escape(order.email)}</div>
  </div>

  <table>
    <thead>
      <tr><th>Item</th><th>Type</th><th>Due back</th><th class="num">Qty</th><th class="num">Price</th></tr>
    </thead>
    <tbody>
{rows}
    </tbody>
    <tfoot>
      <tr><td colspan="4" class="num">Total amount due</td><td class="num">{money(order.total)}</td></tr>
    </tfoot>
  </table>

  <p class="status">Payment status: <span>Pending</span></p>

  <footer>
    Rented books are charged at {RENT_RATE:.0%} of the book price and are due back {RENT_DAYS} days after the order date.<br>
    This bill was generated automatically when the order was placed.
  </footer>
</body>
</html>
"""


def bill_file_name(order_id: int) -> str:
    """The name recorded with the order. The order id is unique, so the file name is too."""
    return f"{BILLS_FOLDER}/bill-{order_id}.html"


class BillStore:
    """The folder the bills are saved in, so the manager can print and post them (FR9)."""

    def __init__(self, folder: Path):
        self._folder = Path(folder)

    def write(self, order_id: int, bill_html: str) -> str:
        """Save a bill and return its name (bills/bill-<id>.html). Raises OSError if it cannot be written."""
        self._folder.mkdir(parents=True, exist_ok=True)
        path = self._path(order_id)
        # Written beside the real file and then swapped in, in one step: someone opening the
        # bill at the same moment gets the whole old file or the whole new one, never half.
        draft = path.with_suffix(f".{threading.get_ident()}.tmp")
        try:
            draft.write_text(bill_html, encoding="utf-8")
            os.replace(draft, path)
        finally:
            draft.unlink(missing_ok=True)
        return bill_file_name(order_id)

    def read(self, order_id: int) -> Optional[str]:
        """The saved bill, or None if there is no readable file for this order."""
        try:
            return self._path(order_id).read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            return None

    def _path(self, order_id: int) -> Path:
        # int(): the file name is built from a number only, never from text sent by a caller.
        return self._folder / f"bill-{int(order_id)}.html"
