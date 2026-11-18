"""Write docs/02-design/bill/bill-sample.html with order-service's own bill code, so the design
sample is exactly what a real bill looks like.

Run from the repository root:  python tools/diagrams/bill_sample.py
Then render the PNG (see tools/diagrams/README.md).
"""
import sys
from datetime import date, datetime
from decimal import Decimal
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "services" / "order-service"))

from order_service.bill import render_bill  # noqa: E402
from order_service.models import Order, OrderItem  # noqa: E402

items = (
    OrderItem("a" * 24, "Clean Code", "Robert C. Martin", "BUY", 1, Decimal("40.00"), None),
    OrderItem("b" * 24, "Database System Concepts", "Abraham Silberschatz", "BUY", 1, Decimal("55.00"), None),
    OrderItem("c" * 24, "Java Concurrency in Practice", "Brian Goetz", "RENT", 1, Decimal("8.00"), date(2026, 11, 20)),
)
order = Order(1042, 7, "alice", "alice@example.com", datetime(2026, 11, 13, 10, 5), "PENDING", items, Decimal("103.00"), None)
target = ROOT / "docs" / "02-design" / "bill" / "bill-sample.html"
target.write_text(render_bill(order), encoding="utf-8")
print(f"wrote {target.relative_to(ROOT)}")
