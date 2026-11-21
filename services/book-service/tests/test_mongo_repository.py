"""The MongoDB repositories (books and reviews) against a real MongoDB.

Uses its own database, `bookstore_test`, which is emptied before each test and
dropped afterwards, so the real `bookstore` data is never touched. Skipped if
MongoDB is not running.
"""
import os
import unittest
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta

from pymongo import MongoClient
from pymongo.errors import DuplicateKeyError, PyMongoError

from book_service.models import RatingTotals
from book_service.repository import MongoBookRepository, MongoReviewRepository
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

    def test_an_id_in_capitals_finds_the_book_which_keeps_its_own_lowercase_id(self):
        # InMemoryBookRepository copies this; the review service relies on book.id being the canonical form.
        found = self.books.find(self.clean_code.id.upper())
        self.assertEqual(found.id, self.clean_code.id)

    def test_replace_overwrites_the_details(self):
        updated = self.books.replace(self.clean_code.id, BookInput("Clean Code", "Robert C. Martin", 45.5, 9, None))
        self.assertEqual((updated.price, updated.copies_available), (45.5, 9))
        self.assertEqual(self.books.find(self.clean_code.id), updated)
        self.assertIsNone(self.books.replace("ffffffffffffffffffffffff", BookInput("x", "y", 1.0, 1, None)))

    def test_replace_with_an_old_number_of_copies_changes_nothing(self):
        self.books.change_copies(self.clean_code.id, -1)  # an order took one: 4 -> 3
        stale = BookInput("Clean Code", "Robert C. Martin", 45.0, 4, None, copies_before=4)
        self.assertIsNone(self.books.replace(self.clean_code.id, stale))
        self.assertEqual((self.books.find(self.clean_code.id).price, self.books.find(self.clean_code.id).copies_available), (40.0, 3))
        current = BookInput("Clean Code", "Robert C. Martin", 45.0, 5, None, copies_before=3)
        self.assertEqual(self.books.replace(self.clean_code.id, current).copies_available, 5)

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


BOOK_A = "aaaaaaaaaaaaaaaaaaaaaaaa"
BOOK_B = "bbbbbbbbbbbbbbbbbbbbbbbb"


@unittest.skipUnless(mongo_is_running(), "MongoDB is not running")
class MongoReviewRepositoryTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.client = MongoClient(MONGO_URL, serverSelectionTimeoutMS=3000)

    @classmethod
    def tearDownClass(cls):
        cls.client.drop_database(TEST_DATABASE)
        cls.client.close()

    def setUp(self):
        self.collection = self.client[TEST_DATABASE]["reviews"]
        self.collection.drop()  # drops its indexes too, so each test sees the repository create them
        self.reviews = MongoReviewRepository(self.collection)
        self.reviews.ensure_indexes()
        self.now = datetime(2026, 11, 18, 10, 5, 0)

    def test_the_unique_index_is_created_and_creating_it_again_is_harmless(self):
        self.reviews.ensure_indexes()
        MongoReviewRepository(self.collection).ensure_indexes()
        unique = [index for index in self.collection.index_information().values() if index.get("unique")]
        self.assertEqual([index["key"] for index in unique], [[("bookId", 1), ("userId", 1)]])
        self.collection.insert_one({"bookId": BOOK_A, "userId": 1})
        with self.assertRaises(DuplicateKeyError):
            self.collection.insert_one({"bookId": BOOK_A, "userId": 1})

    def test_if_start_up_could_not_create_the_index_the_first_save_does(self):
        self.collection.drop()
        MongoReviewRepository(self.collection).save(BOOK_A, 1, "alice", 4, "", self.now)
        self.assertIn(MongoReviewRepository.INDEX_NAME, self.collection.index_information())

    def test_save_stores_a_review_and_reads_it_back(self):
        saved = self.reviews.save(BOOK_A, 1, "alice", 4, "Loved it", self.now)
        self.assertRegex(saved.id, r"^[0-9a-f]{24}$")
        self.assertEqual((saved.book_id, saved.user_id, saved.username, saved.rating, saved.text), (BOOK_A, 1, "alice", 4, "Loved it"))
        self.assertEqual((saved.created_at, saved.updated_at), (self.now, self.now))
        self.assertEqual(self.reviews.list_for_book(BOOK_A), [saved])
        self.assertEqual(self.reviews.list_for_book(BOOK_B), [])

    def test_a_second_save_for_the_same_book_and_customer_replaces_never_duplicates(self):
        first = self.reviews.save(BOOK_A, 1, "alice", 2, "Hard going", self.now)
        later = self.now + timedelta(days=1)
        second = self.reviews.save(BOOK_A, 1, "alice", 5, "", later)
        self.assertEqual(second.id, first.id)
        self.assertEqual((second.rating, second.text, second.created_at, second.updated_at), (5, "", self.now, later))
        self.assertEqual(self.collection.count_documents({"bookId": BOOK_A, "userId": 1}), 1)

    def test_saves_at_the_same_moment_still_leave_one_review(self):
        with ThreadPoolExecutor(max_workers=10) as pool:
            list(pool.map(lambda rating: self.reviews.save(BOOK_A, 1, "alice", rating % 5 + 1, "", self.now), range(10)))
        self.assertEqual(self.collection.count_documents({"bookId": BOOK_A, "userId": 1}), 1)

    def test_newest_first(self):
        self.reviews.save(BOOK_A, 1, "alice", 3, "", self.now)
        self.reviews.save(BOOK_A, 2, "bob", 5, "", self.now + timedelta(minutes=1))
        self.reviews.save(BOOK_A, 1, "alice", 4, "", self.now + timedelta(minutes=2))
        self.assertEqual([r.username for r in self.reviews.list_for_book(BOOK_A)], ["alice", "bob"])

    def test_delete_removes_only_that_customers_review(self):
        self.reviews.save(BOOK_A, 1, "alice", 3, "", self.now)
        self.reviews.save(BOOK_A, 2, "bob", 5, "", self.now)
        self.reviews.save(BOOK_B, 1, "alice", 1, "", self.now)
        self.assertTrue(self.reviews.delete(BOOK_A, 1))
        self.assertFalse(self.reviews.delete(BOOK_A, 1), "already gone")
        self.assertEqual([r.username for r in self.reviews.list_for_book(BOOK_A)], ["bob"])
        self.assertEqual(len(self.reviews.list_for_book(BOOK_B)), 1)

    def test_rating_totals_group_by_book_in_one_aggregation(self):
        self.reviews.save(BOOK_A, 1, "alice", 4, "", self.now)
        self.reviews.save(BOOK_A, 2, "bob", 5, "", self.now)
        self.reviews.save(BOOK_A, 3, "carol", 5, "", self.now)
        self.reviews.save(BOOK_B, 1, "alice", 2, "", self.now)
        self.reviews.save("cccccccccccccccccccccccc", 1, "alice", 1, "", self.now)
        totals = self.reviews.rating_totals([BOOK_A, BOOK_B, "dddddddddddddddddddddddd"])
        self.assertEqual(totals, {BOOK_A: RatingTotals(14, 3), BOOK_B: RatingTotals(2, 1)}, "only the books asked for; none for a book without reviews")
        self.assertEqual(self.reviews.rating_totals([]), {})


if __name__ == "__main__":
    unittest.main()
