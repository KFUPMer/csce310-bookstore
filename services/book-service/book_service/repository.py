"""Reads and writes books and their reviews.

`BookRepository` and `ReviewRepository` say what the rules need from storage.
The MongoDB classes are the real ones. The in-memory ones are for tests, so
the rules can be tested without a database.
"""
import re
from abc import ABC, abstractmethod
from datetime import datetime
from typing import Iterable, Optional

from bson import ObjectId
from bson.errors import InvalidId
from pymongo import ASCENDING, DESCENDING, ReturnDocument
from pymongo.collection import Collection
from pymongo.errors import DuplicateKeyError

from .models import Book, RatingTotals, Review
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
        return self._books.get(self._key(book_id))

    @staticmethod
    def _key(book_id: str) -> str:
        """MongoDB reads an id in any capitalisation as the same ObjectId; so does this."""
        return book_id.lower() if isinstance(book_id, str) else book_id

    def insert(self, book: BookInput) -> Book:
        # Letters in the id, like a real ObjectId, so tests can tell "AB12" from "ab12".
        book_id = f"{0x65AB0000000000000000000 + self._next_id:024x}"
        self._next_id += 1
        self._books[book_id] = Book(book_id, book.title, book.author, book.price, book.copies_available, book.cover_url, book.category)
        return self._books[book_id]

    def replace(self, book_id: str, book: BookInput) -> Optional[Book]:
        book_id = self._key(book_id)
        if book_id not in self._books:
            return None
        self._books[book_id] = Book(book_id, book.title, book.author, book.price, book.copies_available, book.cover_url, book.category)
        return self._books[book_id]

    def change_copies(self, book_id: str, change: int) -> Optional[Book]:
        book_id = self._key(book_id)
        current = self._books.get(book_id)
        if current is None or current.copies_available + change < 0:
            return None
        updated = Book(current.id, current.title, current.author, current.price, current.copies_available + change, current.cover_url, current.category)
        self._books[book_id] = updated
        return updated


class ReviewRepository(ABC):
    @abstractmethod
    def list_for_book(self, book_id: str) -> list[Review]:
        """The book's reviews, the most recently written or changed first."""

    @abstractmethod
    def save(self, book_id: str, user_id: int, username: str, rating: int, text: str, now: datetime) -> Review:
        """Create this customer's review of this book, or replace it if there is one.
        A replaced review keeps its creation time; `now` becomes its update time."""

    @abstractmethod
    def delete(self, book_id: str, user_id: int) -> bool:
        """Remove this customer's review of this book. False if there was none."""

    @abstractmethod
    def rating_totals(self, book_ids: Iterable[str]) -> dict[str, RatingTotals]:
        """The stars and number of reviews of each of these books. A book without reviews is left out."""


class MongoReviewRepository(ReviewRepository):
    """Reviews in the MongoDB collection `reviews`, next to `books`."""

    INDEX_NAME = "one_review_per_customer_per_book"

    def __init__(self, collection: Collection):
        self._reviews = collection
        self._indexes_ready = False

    def ensure_indexes(self) -> None:
        """Create the unique (bookId, userId) index if it is not there yet. Safe to call again."""
        self._reviews.create_index([("bookId", ASCENDING), ("userId", ASCENDING)], unique=True, name=self.INDEX_NAME)
        self._indexes_ready = True

    def list_for_book(self, book_id: str) -> list[Review]:
        # _id breaks ties between reviews changed in the same second, so the order never wobbles.
        found = self._reviews.find({"bookId": book_id}).sort([("updatedAt", DESCENDING), ("_id", DESCENDING)])
        return [self._to_review(doc) for doc in found]

    def save(self, book_id: str, user_id: int, username: str, rating: int, text: str, now: datetime) -> Review:
        if not self._indexes_ready:
            # Start-up could not reach MongoDB to create the index; it must exist before the first write.
            self.ensure_indexes()
        query = {"bookId": book_id, "userId": user_id}
        change = {"$set": {"username": username, "rating": rating, "text": text, "updatedAt": now}, "$setOnInsert": {"createdAt": now}}
        try:
            doc = self._reviews.find_one_and_update(query, change, upsert=True, return_document=ReturnDocument.AFTER)
        except DuplicateKeyError:
            # Two saves for the same customer and book at the same moment both tried to create the
            # review; the unique index let only one through. Now that it exists, this one replaces it.
            doc = self._reviews.find_one_and_update(query, change, upsert=True, return_document=ReturnDocument.AFTER)
        return self._to_review(doc)

    def delete(self, book_id: str, user_id: int) -> bool:
        return self._reviews.delete_one({"bookId": book_id, "userId": user_id}).deleted_count == 1

    def rating_totals(self, book_ids: Iterable[str]) -> dict[str, RatingTotals]:
        book_ids = list(book_ids)
        if not book_ids:
            return {}
        # One aggregation for all the books, however many there are, rather than one query per book.
        pipeline = [
            {"$match": {"bookId": {"$in": book_ids}}},
            {"$group": {"_id": "$bookId", "stars": {"$sum": "$rating"}, "count": {"$sum": 1}}},
        ]
        return {row["_id"]: RatingTotals(int(row["stars"]), int(row["count"])) for row in self._reviews.aggregate(pipeline)}

    @staticmethod
    def _to_review(doc: dict) -> Review:
        return Review(
            id=str(doc["_id"]),
            book_id=doc["bookId"],
            user_id=int(doc["userId"]),
            username=doc["username"],
            rating=int(doc["rating"]),
            text=doc.get("text") or "",
            created_at=doc["createdAt"],
            updated_at=doc["updatedAt"],
        )


class InMemoryReviewRepository(ReviewRepository):
    """Reviews kept in memory, for tests. Behaves like the MongoDB one."""

    def __init__(self):
        self._reviews: dict[tuple[str, int], Review] = {}
        self._next_id = 1

    def list_for_book(self, book_id: str) -> list[Review]:
        found = [r for r in self._reviews.values() if r.book_id == book_id]
        return sorted(found, key=lambda r: (r.updated_at, r.id), reverse=True)

    def save(self, book_id: str, user_id: int, username: str, rating: int, text: str, now: datetime) -> Review:
        current = self._reviews.get((book_id, user_id))
        if current is None:
            review_id, created_at = f"{self._next_id:024x}", now
            self._next_id += 1
        else:
            review_id, created_at = current.id, current.created_at
        review = Review(review_id, book_id, user_id, username, rating, text, created_at, now)
        self._reviews[(book_id, user_id)] = review
        return review

    def delete(self, book_id: str, user_id: int) -> bool:
        return self._reviews.pop((book_id, user_id), None) is not None

    def rating_totals(self, book_ids: Iterable[str]) -> dict[str, RatingTotals]:
        wanted = set(book_ids)
        totals: dict[str, RatingTotals] = {}
        for review in self._reviews.values():
            if review.book_id in wanted:
                before = totals.get(review.book_id, RatingTotals(0, 0))
                totals[review.book_id] = RatingTotals(before.stars + review.rating, before.count + 1)
        return totals
