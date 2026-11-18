"""The rules about books and their reviews. Knows nothing about HTTP or MongoDB."""
from dataclasses import replace
from datetime import datetime
from decimal import ROUND_HALF_UP, Decimal
from typing import Callable, Optional

from .errors import ConflictError, NotFoundError
from .models import Book, CurrentUser, RatingTotals, Review
from .repository import BookRepository, ReviewRepository
from .schemas import BookInput, ReviewInput

NOT_FOUND = "This book does not exist"
NOT_REVIEWED = "You have not reviewed this book"


def average_rating(totals: RatingTotals) -> float:
    """The average to one decimal, a half rounded up (4.25 shows as 4.3, as a person would expect)."""
    average = Decimal(totals.stars) / Decimal(totals.count)
    return float(average.quantize(Decimal("0.1"), rounding=ROUND_HALF_UP))


class BookService:
    def __init__(self, books: BookRepository, reviews: ReviewRepository):
        self._books = books
        self._reviews = reviews

    def search(self, keyword: str, category: Optional[str] = None) -> list[Book]:
        """FR4, FR5: books whose title or author contains the keyword. No keyword lists them all.
        A category keeps only that shelf."""
        return self._with_ratings(self._books.search(keyword or "", category))

    def get(self, book_id: str) -> Book:
        return self._with_rating(self._find(book_id))

    def add(self, book: BookInput) -> Book:
        """FR14: add a new book."""
        return self._with_rating(self._books.insert(book))

    def update(self, book_id: str, book: BookInput) -> Book:
        """FR14: change a book's details, such as the number of available copies."""
        updated = self._books.replace(book_id, book)
        if updated is None:
            raise NotFoundError(NOT_FOUND)
        return self._with_rating(updated)

    def change_copies(self, book_id: str, change: int) -> Book:
        """Take copies when a book is ordered (negative change) or give them back.

        Raises ConflictError rather than letting the number of copies go below zero.
        """
        updated = self._books.change_copies(book_id, change)
        if updated is not None:
            return self._with_rating(updated)
        # It failed: say why. Either there is no such book, or there are not enough copies.
        book = self._find(book_id)
        if book.copies_available == 0:
            raise ConflictError(f'"{book.title}" is not available')
        raise ConflictError(f'Only {book.copies_available} of "{book.title}" left')

    def _find(self, book_id: str) -> Book:
        book = self._books.find(book_id)
        if book is None:
            raise NotFoundError(NOT_FOUND)
        return book

    def _with_rating(self, book: Book) -> Book:
        return self._with_ratings([book])[0]

    def _with_ratings(self, books: list[Book]) -> list[Book]:
        """The books with their ratings filled in, read with one query for all of them."""
        totals = self._reviews.rating_totals(book.id for book in books)
        rated = []
        for book in books:
            found = totals.get(book.id)
            rated.append(replace(book, rating_average=average_rating(found), rating_count=found.count) if found else book)
        return rated


class ReviewService:
    """Reviews and ratings (extra credit). Who may write them (customers) is checked by the routes."""

    def __init__(self, books: BookRepository, reviews: ReviewRepository, clock: Callable[[], datetime] = datetime.now):
        self._books = books
        self._reviews = reviews
        self._clock = clock

    def list_for_book(self, book_id: str) -> list[Review]:
        return self._reviews.list_for_book(self._book_id(book_id))

    def save_mine(self, book_id: str, user: CurrentUser, review: ReviewInput) -> Review:
        """Write the customer's review of the book, or replace the one they wrote before."""
        book_id = self._book_id(book_id)
        # Whole seconds, like every other time in the project.
        now = self._clock().replace(microsecond=0)
        return self._reviews.save(book_id, user.user_id, user.username, review.rating, review.text, now)

    def delete_mine(self, book_id: str, user: CurrentUser) -> None:
        if not self._reviews.delete(self._book_id(book_id), user.user_id):
            raise NotFoundError(NOT_REVIEWED)

    def _book_id(self, book_id: str) -> str:
        """The book's own id. MongoDB also finds a book by its id in capitals, but reviews must be
        kept under one spelling, or the one-review-per-customer index and the ratings miss them."""
        book = self._books.find(book_id)
        if book is None:
            raise NotFoundError(NOT_FOUND)
        return book.id
