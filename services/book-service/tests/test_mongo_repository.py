"""The MongoDB repository against a real MongoDB.

Uses its own database, `bookstore_test`, which is emptied before each test and
dropped afterwards, so the real `bookstore` data is never touched. Skipped if
MongoDB is not running.
"""
import os
import unittest
from concurrent.futures import ThreadPoolExecutor

from pymongo import MongoClient
from pymongo.errors import PyMongoError

from book_service.repository import MongoBookRepository
from book_service.schemas import BookInput

MONGO_URL = os.environ.get("MONGO_URL", "mongodb://localhost:27017")
TEST_DATABASE = "bookstore_test"


def mongo_is_running() -> bool:
    try:
        MongoClient(MONGO_URL, serverSelectionTimeoutMS=1000).admin.command("ping")
        return True
    except PyMongoError:
        return False


@unittest.skipUnless(mongo_is_running(), "MongoDB is not running")
class MongoBookRepositoryTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.client = MongoClient(MONGO_URL, serverSelectionTimeoutMS=3000)

    @classmethod
    def tearDownClass(cls):
        cls.client.drop_database(TEST_DATABASE)
        cls.client.close()

    def setUp(self):
        collection = self.client[TEST_DATABASE]["books"]
        collection.delete_many({})
        self.books = MongoBookRepository(collection)
        self.clean_code = self.books.insert(BookInput("Clean Code", "Robert C. Martin", 40.0, 4, None))
        self.effective_java = self.books.insert(BookInput("Effective Java", "Joshua Bloch", 50.0, 2, "https://example.com/cover.jpg"))
        self.cpp = self.books.insert(BookInput("The C++ Programming Language", "Bjarne Stroustrup", 70.0, 1, None))

    def test_search_matches_title_or_author_ignoring_case(self):
        self.assertEqual([b.title for b in self.books.search("JAVA")], ["Effective Java"])
        self.assertEqual([b.title for b in self.books.search("martin")], ["Clean Code"])
        self.assertEqual([b.title for b in self.books.search("  bloch ")], ["Effective Java"])

    def test_an_empty_keyword_returns_everything_sorted_by_title(self):
        self.assertEqual([b.title for b in self.books.search("")], ["Clean Code", "Effective Java", "The C++ Programming Language"])

    def test_special_characters_are_searched_as_plain_text(self):
        self.assertEqual([b.title for b in self.books.search("c++")], ["The C++ Programming Language"])
        self.assertEqual(self.books.search(".*"), [])
        self.assertEqual(self.books.search("("), [])

    def test_a_category_is_stored_and_filters_the_search(self):
        gatsby = self.books.insert(BookInput("The Great Gatsby", "F. Scott Fitzgerald", 14.0, 4, None, "Fiction"))
        self.assertEqual(self.books.find(gatsby.id).category, "Fiction")
        self.assertEqual([b.title for b in self.books.search("", "Fiction")], ["The Great Gatsby"])
        self.assertEqual([b.title for b in self.books.search("gatsby", "Technology")], [])
        self.assertEqual(len(self.books.search("", None)), 4, "no category: every book")

    def test_find_by_id_and_unknown_ids(self):
        self.assertEqual(self.books.find(self.effective_java.id).cover_url, "https://example.com/cover.jpg")
        self.assertIsNone(self.books.find("ffffffffffffffffffffffff"))
        self.assertIsNone(self.books.find("not-an-id"))

    def test_replace_overwrites_the_details(self):
        updated = self.books.replace(self.clean_code.id, BookInput("Clean Code", "Robert C. Martin", 45.5, 9, None))
        self.assertEqual((updated.price, updated.copies_available), (45.5, 9))
        self.assertEqual(self.books.find(self.clean_code.id), updated)
        self.assertIsNone(self.books.replace("ffffffffffffffffffffffff", BookInput("x", "y", 1.0, 1, None)))

    def test_copies_change_but_never_go_below_zero(self):
        self.assertEqual(self.books.change_copies(self.clean_code.id, -3).copies_available, 1)
        self.assertEqual(self.books.change_copies(self.clean_code.id, -1).copies_available, 0)
        self.assertIsNone(self.books.change_copies(self.clean_code.id, -1))
        self.assertEqual(self.books.find(self.clean_code.id).copies_available, 0)
        self.assertEqual(self.books.change_copies(self.clean_code.id, 2).copies_available, 2)

    def test_two_orders_at_once_cannot_both_take_the_last_copy(self):
        # The C++ book has exactly 1 copy. Twenty attempts at the same moment: exactly one may succeed.
        with ThreadPoolExecutor(max_workers=20) as pool:
            results = list(pool.map(lambda _: self.books.change_copies(self.cpp.id, -1), range(20)))
        self.assertEqual(sum(1 for r in results if r is not None), 1)
        self.assertEqual(self.books.find(self.cpp.id).copies_available, 0)


if __name__ == "__main__":
    unittest.main()
