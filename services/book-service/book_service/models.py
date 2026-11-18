"""Plain data."""
from dataclasses import dataclass
from typing import Optional

# The shelves of the store, in the order the apps show them (added at the owner's request, beyond
# the PRD). The apps hold the same list in bookstore-ui (book.dart, `categories`).
CATEGORIES = ("Fiction", "Nonfiction", "Kids", "Science", "Technology")
CATEGORY_PROBLEM = "Choose a category: Fiction, Nonfiction, Kids, Science, or Technology"


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
    category: Optional[str] = None
    """One of CATEGORIES; None for a book stored before categories existed."""

    def to_json(self) -> dict:
        """The shape every endpoint returns (docs/02-design/api-design.md)."""
        return {
            "id": self.id,
            "title": self.title,
            "author": self.author,
            "price": self.price,
            "copiesAvailable": self.copies_available,
            "coverUrl": self.cover_url,
            "category": self.category,
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
