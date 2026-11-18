"""Reads and writes books.

`BookRepository` says what the rules need from storage. `MongoBookRepository`
is the real one. `InMemoryBookRepository` is for tests, so the rules can be
tested without a database.
"""
import re
from abc import ABC, abstractmethod
from typing import Optional

from bson import ObjectId
from bson.errors import InvalidId
from pymongo import ReturnDocument
from pymongo.collection import Collection

from .models import Book
from .schemas import BookInput


class BookRepository(ABC):
    @abstractmethod
    def search(self, keyword: str, category: Optional[str] = None) -> list[Book]:
        """Books whose title or author contains `keyword`, ignoring case, sorted by title.
        An empty keyword returns every book. A category keeps only the books on that shelf."""

    @abstractmethod
    def find(self, book_id: str) -> Optional[Book]:
        """The book with this id, or None."""

    @abstractmethod
    def insert(self, book: BookInput) -> Book:
        """Store a new book and return it with its id."""

    @abstractmethod
    def replace(self, book_id: str, book: BookInput) -> Optional[Book]:
        """Overwrite a book's details. Returns the updated book, or None if it does not exist."""

    @abstractmethod
    def change_copies(self, book_id: str, change: int) -> Optional[Book]:
        """Add `change` copies (negative takes copies away), but only if the result is not
        below zero. Returns the updated book, or None if that was not possible."""


class MongoBookRepository(BookRepository):
    """Books in the MongoDB collection `books`."""

    def __init__(self, collection: Collection):
        self._books = collection

    def search(self, keyword: str, category: Optional[str] = None) -> list[Book]:
        keyword = keyword.strip()
        query = {}
        if keyword:
            # re.escape: the keyword is matched as plain text, so characters such as
            # "(" or "+" typed by a user cannot change or break the search.
            pattern = {"$regex": re.escape(keyword), "$options": "i"}
            query = {"$or": [{"title": pattern}, {"author": pattern}]}  # FR4: title AND author
        if category:
            query["category"] = category  # checked against CATEGORIES before it gets here
        return [self._to_book(doc) for doc in self._books.find(query).sort("title", 1)]

    def find(self, book_id: str) -> Optional[Book]:
        oid = self._object_id(book_id)
        doc = self._books.find_one({"_id": oid}) if oid else None
        return self._to_book(doc) if doc else None

    def insert(self, book: BookInput) -> Book:
        doc = self._to_document(book)
        result = self._books.insert_one(doc)
        return self._to_book({**doc, "_id": result.inserted_id})

    def replace(self, book_id: str, book: BookInput) -> Optional[Book]:
        oid = self._object_id(book_id)
        if not oid:
            return None
        doc = self._books.find_one_and_update({"_id": oid}, {"$set": self._to_document(book)}, return_document=ReturnDocument.AFTER)
        return self._to_book(doc) if doc else None

    def change_copies(self, book_id: str, change: int) -> Optional[Book]:
        oid = self._object_id(book_id)
        if not oid:
            return None
        # One atomic step: the condition and the change happen together, so two orders
        # placed at the same moment cannot both take the last copy.
        doc = self._books.find_one_and_update(
            {"_id": oid, "copiesAvailable": {"$gte": -change}},
            {"$inc": {"copiesAvailable": change}},
            return_document=ReturnDocument.AFTER,
        )
        return self._to_book(doc) if doc else None

    @staticmethod
    def _object_id(book_id: str) -> Optional[ObjectId]:
        """An id that is not in MongoDB's format cannot belong to any book."""
        try:
            return ObjectId(book_id)
        except (InvalidId, TypeError):
            return None

    @staticmethod
    def _to_document(book: BookInput) -> dict:
        return {"title": book.title, "author": book.author, "price": book.price, "copiesAvailable": book.copies_available, "coverUrl": book.cover_url, "category": book.category}

    @staticmethod
    def _to_book(doc: dict) -> Book:
        return Book(
            id=str(doc["_id"]),
            title=doc["title"],
            author=doc["author"],
            price=float(doc["price"]),
            copies_available=int(doc["copiesAvailable"]),
            cover_url=doc.get("coverUrl"),
            category=doc.get("category"),
        )


class InMemoryBookRepository(BookRepository):
    """Books kept in memory, for tests. Behaves like the MongoDB one."""

    def __init__(self):
        self._books: dict[str, Book] = {}
        self._next_id = 1

    def search(self, keyword: str, category: Optional[str] = None) -> list[Book]:
        keyword = keyword.strip().lower()
        found = [
            b for b in self._books.values()
            if (not keyword or keyword in b.title.lower() or keyword in b.author.lower()) and (not category or b.category == category)
        ]
        return sorted(found, key=lambda b: b.title)

    def find(self, book_id: str) -> Optional[Book]:
        return self._books.get(book_id)

    def insert(self, book: BookInput) -> Book:
        book_id = f"{self._next_id:024x}"
        self._next_id += 1
        self._books[book_id] = Book(book_id, book.title, book.author, book.price, book.copies_available, book.cover_url, book.category)
        return self._books[book_id]

    def replace(self, book_id: str, book: BookInput) -> Optional[Book]:
        if book_id not in self._books:
            return None
        self._books[book_id] = Book(book_id, book.title, book.author, book.price, book.copies_available, book.cover_url, book.category)
        return self._books[book_id]

    def change_copies(self, book_id: str, change: int) -> Optional[Book]:
        current = self._books.get(book_id)
        if current is None or current.copies_available + change < 0:
            return None
        updated = Book(current.id, current.title, current.author, current.price, current.copies_available + change, current.cover_url, current.category)
        self._books[book_id] = updated
        return updated
