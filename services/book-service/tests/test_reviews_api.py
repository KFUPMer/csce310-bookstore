"""Reviews and ratings (extra credit): every review endpoint, each success and each error message,
and the ratings shown on the books.

Uses Flask's test client with in-memory repositories, a fake user-service and a clock the test sets.
"""
import unittest
from datetime import datetime, timedelta

from book_service.app import create_app
from book_service.repository import InMemoryBookRepository, InMemoryReviewRepository
from book_service.schemas import BookInput

from .fakes import SERVICE_KEY, FakeSessionChecker, as_customer, as_manager, as_other_customer

UNKNOWN_BOOK = "ffffffffffffffffffffffff"


class ReviewsApiTest(unittest.TestCase):
    def setUp(self):
        self.books = InMemoryBookRepository()
        self.reviews = InMemoryReviewRepository()
        self.now = datetime(2026, 11, 18, 10, 5, 0, 123456)
        self.client = create_app(self.books, self.reviews, FakeSessionChecker(), SERVICE_KEY, clock=lambda: self.now).test_client()
        self.clean_code = self.books.insert(BookInput("Clean Code", "Robert C. Martin", 40.0, 4, None, "Technology"))
        self.gatsby = self.books.insert(BookInput("The Great Gatsby", "F. Scott Fitzgerald", 14.0, 4, None, "Fiction"))

    def mine(self, book_id: str) -> str:
        return f"/api/books/{book_id}/reviews/mine"

    def assert_error(self, response, status, message):
        self.assertEqual(response.status_code, status, response.get_data(as_text=True))
        self.assertEqual(response.get_json(), {"error": message})

    # ------------------------------------------------------------ writing a review

    def test_a_customer_reviews_a_book(self):
        response = self.client.put(self.mine(self.clean_code.id), json={"rating": 4, "text": "  Loved it  "}, headers=as_customer())
        self.assertEqual(response.status_code, 200, response.get_data(as_text=True))
        review = response.get_json()
        self.assertRegex(review.pop("id"), r"^[0-9a-f]{24}$")
        self.assertEqual(review, {
            "bookId": self.clean_code.id, "username": "alice", "rating": 4, "text": "Loved it",
            "createdAt": "2026-11-18T10:05:00", "updatedAt": "2026-11-18T10:05:00",
        })

    def test_the_text_is_optional(self):
        for body in [{"rating": 5}, {"rating": 5, "text": None}, {"rating": 5, "text": "   "}]:
            with self.subTest(body=body):
                response = self.client.put(self.mine(self.clean_code.id), json=body, headers=as_customer())
                self.assertEqual(response.status_code, 200)
                self.assertEqual(response.get_json()["text"], "")

    def test_a_second_review_replaces_the_first_and_keeps_when_it_was_written(self):
        first = self.client.put(self.mine(self.clean_code.id), json={"rating": 2, "text": "Hard going"}, headers=as_customer()).get_json()
        self.now += timedelta(days=1, hours=2)
        second = self.client.put(self.mine(self.clean_code.id), json={"rating": 5, "text": "Better the second time"}, headers=as_customer()).get_json()
        self.assertEqual(second["id"], first["id"])
        self.assertEqual(second["rating"], 5)
        self.assertEqual(second["text"], "Better the second time")
        self.assertEqual(second["createdAt"], "2026-11-18T10:05:00")
        self.assertEqual(second["updatedAt"], "2026-11-19T12:05:00")
        listed = self.client.get(f"/api/books/{self.clean_code.id}/reviews", headers=as_customer()).get_json()
        self.assertEqual(listed, [second], "one review per customer per book")

    def test_the_rating_must_be_a_whole_number_from_1_to_5(self):
        for body in [{}, {"rating": None}, {"rating": 0}, {"rating": 6}, {"rating": -1}, {"rating": 4.5}, {"rating": 4.0}, {"rating": "4"}, {"rating": True}, {"rating": False}]:
            with self.subTest(body=body):
                response = self.client.put(self.mine(self.clean_code.id), json=body, headers=as_customer())
                self.assert_error(response, 400, "Choose a rating from 1 to 5 stars")
        self.assertEqual(self.reviews.list_for_book(self.clean_code.id), [], "nothing was stored")

    def test_the_text_can_be_at_most_1000_characters_after_trimming(self):
        too_long = self.client.put(self.mine(self.clean_code.id), json={"rating": 3, "text": "x" * 1001}, headers=as_customer())
        self.assert_error(too_long, 400, "The review can be at most 1000 characters")
        just_right = self.client.put(self.mine(self.clean_code.id), json={"rating": 3, "text": "  " + "x" * 1000 + "  "}, headers=as_customer())
        self.assertEqual(just_right.status_code, 200)
        self.assertEqual(len(just_right.get_json()["text"]), 1000)

    def test_text_that_is_not_text_is_400(self):
        response = self.client.put(self.mine(self.clean_code.id), json={"rating": 3, "text": 42}, headers=as_customer())
        self.assert_error(response, 400, "Write the review as text")

    def test_a_body_that_is_not_a_json_object_is_400(self):
        self.assert_error(self.client.put(self.mine(self.clean_code.id), json=[4], headers=as_customer()), 400, "Send the book as a JSON object")
        not_json = self.client.put(self.mine(self.clean_code.id), data="four stars", headers=as_customer())
        self.assert_error(not_json, 400, "The request body is not valid JSON")

    def test_a_manager_cannot_review(self):
        self.assert_error(self.client.put(self.mine(self.clean_code.id), json={"rating": 5}, headers=as_manager()), 403, "Only a customer can review books")
        self.assertEqual(self.reviews.list_for_book(self.clean_code.id), [])

    def test_reviewing_an_unknown_book_is_404(self):
        for book_id in [UNKNOWN_BOOK, "not-an-id"]:
            with self.subTest(book_id=book_id):
                response = self.client.put(self.mine(book_id), json={"rating": 5}, headers=as_customer())
                self.assert_error(response, 404, "This book does not exist")

    def test_the_id_in_any_capitalisation_is_the_same_book_and_the_same_review(self):
        # MongoDB reads an id in upper or mixed case as the same book, so the review must be kept under the book's own id.
        lower = self.clean_code.id
        upper = lower.upper()
        mixed = lower[:12] + lower[12:].upper()
        for book_id, rating in [(lower, 3), (upper, 4), (mixed, 5)]:
            with self.subTest(book_id=book_id):
                response = self.client.put(self.mine(book_id), json={"rating": rating}, headers=as_customer())
                self.assertEqual(response.status_code, 200, response.get_data(as_text=True))
                self.assertEqual(response.get_json()["bookId"], lower)
        self.assertEqual([r.rating for r in self.reviews.list_for_book(lower)], [5], "still one review per customer per book")
        book = self.client.get(f"/api/books/{upper}", headers=as_customer()).get_json()
        self.assertEqual((book["ratingAverage"], book["ratingCount"]), (5.0, 1))
        listed = self.client.get(f"/api/books/{upper}/reviews", headers=as_customer()).get_json()
        self.assertEqual([r["rating"] for r in listed], [5])
        self.assertEqual(self.client.delete(self.mine(mixed), headers=as_customer()).status_code, 204)
        self.assertEqual(self.reviews.list_for_book(lower), [])

    # ------------------------------------------------------------ reading the reviews

    def test_reviews_are_listed_newest_first(self):
        self.client.put(self.mine(self.clean_code.id), json={"rating": 3, "text": "Fine"}, headers=as_customer())
        self.now += timedelta(minutes=5)
        self.client.put(self.mine(self.clean_code.id), json={"rating": 5, "text": "Great"}, headers=as_other_customer())
        self.client.put(self.mine(self.gatsby.id), json={"rating": 1}, headers=as_customer())
        response = self.client.get(f"/api/books/{self.clean_code.id}/reviews", headers=as_manager())
        self.assertEqual(response.status_code, 200)
        self.assertEqual([(r["username"], r["rating"]) for r in response.get_json()], [("bob", 5), ("alice", 3)])

    def test_an_edited_review_moves_to_the_top(self):
        self.client.put(self.mine(self.clean_code.id), json={"rating": 3}, headers=as_customer())
        self.now += timedelta(minutes=5)
        self.client.put(self.mine(self.clean_code.id), json={"rating": 5}, headers=as_other_customer())
        self.now += timedelta(minutes=5)
        self.client.put(self.mine(self.clean_code.id), json={"rating": 4}, headers=as_customer())
        listed = self.client.get(f"/api/books/{self.clean_code.id}/reviews", headers=as_customer()).get_json()
        self.assertEqual([r["username"] for r in listed], ["alice", "bob"])

    def test_a_book_without_reviews_has_an_empty_list(self):
        response = self.client.get(f"/api/books/{self.gatsby.id}/reviews", headers=as_customer())
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json(), [])

    def test_the_reviews_of_an_unknown_book_is_404(self):
        for book_id in [UNKNOWN_BOOK, "not-an-id"]:
            with self.subTest(book_id=book_id):
                self.assert_error(self.client.get(f"/api/books/{book_id}/reviews", headers=as_customer()), 404, "This book does not exist")

    # ------------------------------------------------------------ deleting a review

    def test_a_customer_deletes_their_review(self):
        self.client.put(self.mine(self.clean_code.id), json={"rating": 2}, headers=as_customer())
        self.client.put(self.mine(self.clean_code.id), json={"rating": 4}, headers=as_other_customer())
        response = self.client.delete(self.mine(self.clean_code.id), headers=as_customer())
        self.assertEqual(response.status_code, 204)
        self.assertEqual(response.get_data(), b"")
        listed = self.client.get(f"/api/books/{self.clean_code.id}/reviews", headers=as_customer()).get_json()
        self.assertEqual([r["username"] for r in listed], ["bob"], "only alice's review is gone")

    def test_deleting_a_review_that_was_never_written_is_404(self):
        self.assert_error(self.client.delete(self.mine(self.clean_code.id), headers=as_customer()), 404, "You have not reviewed this book")
        self.client.put(self.mine(self.clean_code.id), json={"rating": 4}, headers=as_customer())
        self.client.delete(self.mine(self.clean_code.id), headers=as_customer())
        self.assert_error(self.client.delete(self.mine(self.clean_code.id), headers=as_customer()), 404, "You have not reviewed this book")

    def test_deleting_on_an_unknown_book_is_404(self):
        self.assert_error(self.client.delete(self.mine(UNKNOWN_BOOK), headers=as_customer()), 404, "This book does not exist")
        self.assert_error(self.client.delete(self.mine("not-an-id"), headers=as_customer()), 404, "This book does not exist")

    def test_a_manager_cannot_delete_a_review(self):
        self.client.put(self.mine(self.clean_code.id), json={"rating": 4}, headers=as_customer())
        self.assert_error(self.client.delete(self.mine(self.clean_code.id), headers=as_manager()), 403, "Only a customer can review books")
        self.assertEqual(len(self.reviews.list_for_book(self.clean_code.id)), 1)

    # ------------------------------------------------------------ who may ask

    def test_without_a_token_every_review_endpoint_is_401(self):
        self.assert_error(self.client.get(f"/api/books/{self.clean_code.id}/reviews"), 401, "You are not logged in")
        self.assert_error(self.client.put(self.mine(self.clean_code.id), json={"rating": 5}), 401, "You are not logged in")
        self.assert_error(self.client.delete(self.mine(self.clean_code.id)), 401, "You are not logged in")

    # ------------------------------------------------------------ ratings on the books

    def rate(self, book_id: str, rating: int, headers: dict):
        response = self.client.put(self.mine(book_id), json={"rating": rating}, headers=headers)
        self.assertEqual(response.status_code, 200)

    def test_a_book_without_reviews_has_no_average(self):
        book = self.client.get(f"/api/books/{self.gatsby.id}", headers=as_customer()).get_json()
        self.assertIsNone(book["ratingAverage"])
        self.assertEqual(book["ratingCount"], 0)

    def test_ratings_appear_on_get_and_on_search(self):
        self.rate(self.clean_code.id, 4, as_customer())
        self.rate(self.clean_code.id, 5, as_other_customer())
        self.rate(self.gatsby.id, 2, as_customer())
        book = self.client.get(f"/api/books/{self.clean_code.id}", headers=as_customer()).get_json()
        self.assertEqual((book["ratingAverage"], book["ratingCount"]), (4.5, 2))
        found = {b["title"]: (b["ratingAverage"], b["ratingCount"]) for b in self.client.get("/api/books", headers=as_customer()).get_json()}
        self.assertEqual(found, {"Clean Code": (4.5, 2), "The Great Gatsby": (2.0, 1)})

    def test_the_average_is_rounded_to_one_decimal(self):
        self.rate(self.clean_code.id, 4, as_customer())
        self.rate(self.clean_code.id, 5, as_other_customer())
        self.rate(self.gatsby.id, 5, as_customer())
        self.rate(self.gatsby.id, 4, as_other_customer())
        # A third rating through the repository: there are only two customers in the fake user-service.
        self.reviews.save(self.clean_code.id, 9, "carol", 5, "", self.now)
        self.reviews.save(self.gatsby.id, 9, "carol", 4, "", self.now)
        found = {b["title"]: b["ratingAverage"] for b in self.client.get("/api/books", headers=as_customer()).get_json()}
        self.assertEqual(found, {"Clean Code": 4.7, "The Great Gatsby": 4.3})  # 14/3 = 4.67, 13/3 = 4.33

    def test_a_half_rounds_up(self):
        for user_id, rating in enumerate([4, 4, 5, 4], start=10):
            self.reviews.save(self.clean_code.id, user_id, f"customer{user_id}", rating, "", self.now)
        # 17 / 4 = 4.25, shown as 4.3, not banker's rounding's 4.2.
        self.assertEqual(self.client.get(f"/api/books/{self.clean_code.id}", headers=as_customer()).get_json()["ratingAverage"], 4.3)

    def test_ratings_follow_replaced_and_deleted_reviews(self):
        self.rate(self.clean_code.id, 1, as_customer())
        self.rate(self.clean_code.id, 5, as_customer())
        book = self.client.get(f"/api/books/{self.clean_code.id}", headers=as_customer()).get_json()
        self.assertEqual((book["ratingAverage"], book["ratingCount"]), (5.0, 1))
        self.client.delete(self.mine(self.clean_code.id), headers=as_customer())
        book = self.client.get(f"/api/books/{self.clean_code.id}", headers=as_customer()).get_json()
        self.assertEqual((book["ratingAverage"], book["ratingCount"]), (None, 0))

    def test_ratings_appear_on_update_and_copies_change_and_add(self):
        self.rate(self.clean_code.id, 3, as_customer())
        body = {"title": "Clean Code", "author": "Robert C. Martin", "price": 40.0, "copiesAvailable": 10, "category": "Technology"}
        updated = self.client.put(f"/api/books/{self.clean_code.id}", json=body, headers=as_manager()).get_json()
        self.assertEqual((updated["ratingAverage"], updated["ratingCount"]), (3.0, 1))
        changed = self.client.patch(f"/api/books/{self.clean_code.id}/copies", json={"change": -1}, headers={"X-Service-Key": SERVICE_KEY}).get_json()
        self.assertEqual((changed["ratingAverage"], changed["ratingCount"]), (3.0, 1))
        added = self.client.post("/api/books", json={**body, "title": "New"}, headers=as_manager()).get_json()
        self.assertEqual((added["ratingAverage"], added["ratingCount"]), (None, 0))


if __name__ == "__main__":
    unittest.main()
