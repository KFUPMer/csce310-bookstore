"""The rules about books. Knows nothing about HTTP or MongoDB."""
from typing import Optional

from .errors import ConflictError, NotFoundError
from .models import Book
from .repository import BookRepository
from .schemas import BookInput

NOT_FOUND = "This book does not exist"


class BookService:
    def __init__(self, books: BookRepository):
        self._books = books

    def search(self, keyword: str, category: Optional[str] = None) -> list[Book]:
        """FR4, FR5: books whose title or author contains the keyword. No keyword lists them all.
        A category keeps only that shelf."""
        return self._books.search(keyword or "", category)

    def get(self, book_id: str) -> Book:
        book = self._books.find(book_id)
        if book is None:
            raise NotFoundError(NOT_FOUND)
        return book

    def add(self, book: BookInput) -> Book:
        """FR14: add a new book."""
        return self._books.insert(book)

    def update(self, book_id: str, book: BookInput) -> Book:
        """FR14: change a book's details, such as the number of available copies."""
        updated = self._books.replace(book_id, book)
        if updated is None:
            raise NotFoundError(NOT_FOUND)
        return updated

    def change_copies(self, book_id: str, change: int) -> Book:
        """Take copies when a book is ordered (negative change) or give them back.

        Raises ConflictError rather than letting the number of copies go below zero.
        """
        updated = self._books.change_copies(book_id, change)
        if updated is not None:
            return updated
        # It failed: say why. Either there is no such book, or there are not enough copies.
        book = self._books.find(book_id)
        if book is None:
            raise NotFoundError(NOT_FOUND)
        if book.copies_available == 0:
            raise ConflictError(f'"{book.title}" is not available')
        raise ConflictError(f'Only {book.copies_available} of "{book.title}" left')
