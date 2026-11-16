"""What a book costs to buy or to rent. The renting rule of the PRD (FR7) is here and nowhere else.

To change the rule, change the two numbers below: the charge, the due date,
and the wording on the bill all follow.
"""
from decimal import ROUND_HALF_UP, Decimal

from .models import RENT

RENT_RATE = Decimal("0.10")  # renting costs 10% of the book price
RENT_DAYS = 7  # and the book is due back after 7 days

CENT = Decimal("0.01")


def charge_for(price: Decimal, kind: str) -> Decimal:
    """What one copy costs: the book price to buy, RENT_RATE of it to rent (rounded to the cent, half up)."""
    if kind == RENT:
        return (price * RENT_RATE).quantize(CENT, rounding=ROUND_HALF_UP)
    return price.quantize(CENT, rounding=ROUND_HALF_UP)
