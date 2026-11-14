"""What a request body must contain. Checked before anything else runs."""
from dataclasses import dataclass
from typing import Any, Optional

from .errors import ValidationError

TITLE_MAX = 255
AUTHOR_MAX = 255
PRICE_MAX = 100_000
COPIES_MAX = 1_000_000
COVER_URL_MAX = 2000


def _require_object(body: Any) -> dict:
    if not isinstance(body, dict):
        raise ValidationError("Send the book as a JSON object")
    return body


def _text(body: dict, field: str, label: str, maximum: int) -> str:
    value = body.get(field)
    if not isinstance(value, str) or not value.strip():
        raise ValidationError(f"Enter the {label}")
    value = value.strip()
    if len(value) > maximum:
        raise ValidationError(f"The {label} is too long (at most {maximum} characters)")
    return value


def _is_number(value: Any) -> bool:
    # In Python True and False count as numbers; a price of `true` is not a price.
    return isinstance(value, (int, float)) and not isinstance(value, bool)


@dataclass(frozen=True)
class BookInput:
    """The body of POST /api/books and PUT /api/books/{id} (FR14)."""

    title: str
    author: str
    price: float
    copies_available: int
    cover_url: Optional[str]

    @staticmethod
    def from_json(body: Any) -> "BookInput":
        """Read and check a book. Raises ValidationError naming the first field that is wrong."""
        body = _require_object(body)
        title = _text(body, "title", "title", TITLE_MAX)
        author = _text(body, "author", "author", AUTHOR_MAX)

        price = body.get("price")
        if not _is_number(price):
            raise ValidationError("Enter the price as a number")
        if price <= 0:
            raise ValidationError("The price must be greater than 0")
        if price > PRICE_MAX:
            raise ValidationError("The price is too high")

        copies = body.get("copiesAvailable")
        if not isinstance(copies, int) or isinstance(copies, bool):
            raise ValidationError("Enter the number of copies as a whole number")
        if copies < 0:
            raise ValidationError("The number of copies cannot be negative")
        if copies > COPIES_MAX:
            raise ValidationError("The number of copies is too high")

        cover_url = body.get("coverUrl")
        if cover_url is not None:
            if not isinstance(cover_url, str) or not cover_url.startswith(("http://", "https://")):
                raise ValidationError("The cover address must start with http:// or https://")
            if len(cover_url) > COVER_URL_MAX:
                raise ValidationError("The cover address is too long")

        # Prices are money: keep two decimals.
        return BookInput(title, author, round(float(price), 2), copies, cover_url)


@dataclass(frozen=True)
class CopiesChange:
    """The body of PATCH /api/books/{id}/copies: how many copies to add (or, if negative, take)."""

    change: int

    @staticmethod
    def from_json(body: Any) -> "CopiesChange":
        body = _require_object(body)
        change = body.get("change")
        if not isinstance(change, int) or isinstance(change, bool) or change == 0:
            raise ValidationError("Enter the change as a whole number other than 0")
        return CopiesChange(change)
