"""Plain data."""
from dataclasses import dataclass
from datetime import datetime
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
    rating_average: Optional[float] = None
    """The customers' average star rating to one decimal, or None when nobody has reviewed it.
    Worked out from the reviews by BookService, never stored on the book."""
    rating_count: int = 0

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
            "ratingAverage": self.rating_average,
            "ratingCount": self.rating_count,
        }


@dataclass(frozen=True)
class Review:
    """One customer's stars and words about one book (extra credit). One per customer per book."""

    id: str
    book_id: str
    user_id: int
    username: str
    rating: int
    """1 to 5 stars."""
    text: str
    """"" when the customer wrote nothing."""
    created_at: datetime
    updated_at: datetime

    def to_json(self) -> dict:
        # The user id stays inside the service; the apps show the username.
        return {
            "id": self.id,
            "bookId": self.book_id,
            "username": self.username,
            "rating": self.rating,
            "text": self.text,
            "createdAt": self.created_at.isoformat(timespec="seconds"),
            "updatedAt": self.updated_at.isoformat(timespec="seconds"),
        }


@dataclass(frozen=True)
class RatingTotals:
    """All the stars a book has been given, added up, and how many reviews gave them."""

    stars: int
    count: int


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
