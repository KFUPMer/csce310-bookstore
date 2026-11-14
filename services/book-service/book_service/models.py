"""Plain data."""
from dataclasses import dataclass
from typing import Optional


@dataclass(frozen=True)
class Book:
    """A book in the catalog.

    `id` is the MongoDB id as text. `cover_url` is optional: without it the
    apps draw a cover from the title.
    """

    id: str
    title: str
    author: str
    price: float
    copies_available: int
    cover_url: Optional[str] = None

    def to_json(self) -> dict:
        """The shape every endpoint returns (docs/02-design/api-design.md)."""
        return {
            "id": self.id,
            "title": self.title,
            "author": self.author,
            "price": self.price,
            "copiesAvailable": self.copies_available,
            "coverUrl": self.cover_url,
        }


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
