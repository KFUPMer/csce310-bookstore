"""Every endpoint, called the way the apps and order-service will: success and each error.

Uses Flask's test client with an in-memory repository and a fake user-service,
so no database and no other service is needed.
"""
import unittest

from book_service.app import create_app
from book_service.repository import InMemoryBookRepository
from book_service.schemas import BookInput

from .fakes import SERVICE_KEY, FakeSessionChecker, as_customer, as_manager

NEW_BOOK = {"title": "Clean Architecture", "author": "Robert C. Martin", "price": 42.0, "copiesAvailable": 3, "category": "Technology"}


class ApiTest(unittest.TestCase):
    def setUp(self):
        self.repository = InMemoryBookRepository()
        self.sessions = FakeSessionChecker()
        self.client = create_app(self.repository, self.sessions, SERVICE_KEY).test_client()
        self.clean_code = self.repository.insert(BookInput("Clean Code", "Robert C. Martin", 40.0, 4, None, "Technology"))
        self.effective_java = self.repository.insert(BookInput("Effective Java", "Joshua Bloch", 50.0, 2, None, "Technology"))
        self.sold_out = self.repository.insert(BookInput("MongoDB: The Definitive Guide", "Shannon Bradshaw", 44.0, 0, None, "Technology"))
        self.gatsby = self.repository.insert(BookInput("The Great Gatsby", "F. Scott Fitzgerald", 14.0, 4, None, "Fiction"))

    def assert_error(self, response, status, message):
        self.assertEqual(response.status_code, status, response.get_data(as_text=True))
        self.assertEqual(response.get_json(), {"error": message})

    # ------------------------------------------------------------ search (FR4, FR5)

    def test_search_matches_the_title(self):
        response = self.client.get("/api/books?keyword=java", headers=as_customer())
        self.assertEqual(response.status_code, 200)
        self.assertEqual([b["title"] for b in response.get_json()], ["Effective Java"])

    def test_search_matches_the_author_and_ignores_case(self):
        response = self.client.get("/api/books?keyword=MARTIN", headers=as_customer())
        self.assertEqual([b["title"] for b in response.get_json()], ["Clean Code"])

    def test_search_results_show_title_author_and_price(self):
        book = self.client.get("/api/books?keyword=clean", headers=as_customer()).get_json()[0]
        self.assertEqual(book, {"id": self.clean_code.id, "title": "Clean Code", "author": "Robert C. Martin", "price": 40.0, "copiesAvailable": 4, "coverUrl": None, "category": "Technology"})

    def test_no_keyword_lists_every_book_sorted_by_title(self):
        titles = [b["title"] for b in self.client.get("/api/books", headers=as_manager()).get_json()]
        self.assertEqual(titles, ["Clean Code", "Effective Java", "MongoDB: The Definitive Guide", "The Great Gatsby"])

    def test_a_search_with_no_match_is_an_empty_list_not_an_error(self):
        response = self.client.get("/api/books?keyword=cooking", headers=as_customer())
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json(), [])

    def test_special_characters_in_the_keyword_are_plain_text(self):
        for keyword in ["(", "c++", ".*", "[", "\\"]:
            response = self.client.get("/api/books", query_string={"keyword": keyword}, headers=as_customer())
            self.assertEqual(response.status_code, 200, keyword)
            self.assertEqual(response.get_json(), [], keyword)

    # ------------------------------------------------------------ categories (shelves, beyond the PRD)

    def test_a_category_lists_only_its_books(self):
        response = self.client.get("/api/books?category=Fiction", headers=as_customer())
        self.assertEqual(response.status_code, 200)
        self.assertEqual([b["title"] for b in response.get_json()], ["The Great Gatsby"])

    def test_a_category_and_a_keyword_together(self):
        found = self.client.get("/api/books?category=Technology&keyword=java", headers=as_customer()).get_json()
        self.assertEqual([b["title"] for b in found], ["Effective Java"])
        self.assertEqual(self.client.get("/api/books?category=Fiction&keyword=java", headers=as_customer()).get_json(), [])

    def test_an_empty_category_means_every_shelf(self):
        self.assertEqual(len(self.client.get("/api/books?category=", headers=as_customer()).get_json()), 4)

    def test_an_unknown_category_is_400(self):
        self.assert_error(
            self.client.get("/api/books?category=Poetry", headers=as_customer()), 400,
            "Choose a category: Fiction, Nonfiction, Kids, Science, or Technology",
        )

    def test_a_book_stored_before_categories_has_none(self):
        old = self.repository.insert(BookInput("Old Book", "Someone", 10.0, 1, None))
        self.assertIsNone(self.client.get(f"/api/books/{old.id}", headers=as_customer()).get_json()["category"])

    # ------------------------------------------------------------ who may ask (N4, N5)

    def test_without_a_token_every_app_endpoint_is_401(self):
        self.assert_error(self.client.get("/api/books"), 401, "You are not logged in")
        self.assert_error(self.client.get(f"/api/books/{self.clean_code.id}"), 401, "You are not logged in")
        self.assert_error(self.client.post("/api/books", json=NEW_BOOK), 401, "You are not logged in")
        self.assert_error(self.client.put(f"/api/books/{self.clean_code.id}", json=NEW_BOOK), 401, "You are not logged in")

    def test_an_ended_session_is_401(self):
        response = self.client.get("/api/books", headers={"Authorization": "Bearer old-token"})
        self.assert_error(response, 401, "Your session has ended. Please log in again.")

    def test_a_customer_cannot_add_or_change_books(self):
        self.assert_error(self.client.post("/api/books", json=NEW_BOOK, headers=as_customer()), 403, "Only a manager can do this")
        self.assert_error(self.client.put(f"/api/books/{self.clean_code.id}", json=NEW_BOOK, headers=as_customer()), 403, "Only a manager can do this")
        self.assertEqual(self.repository.find(self.clean_code.id).title, "Clean Code", "nothing was changed")

    def test_when_user_service_is_down_the_answer_is_503_not_a_crash(self):
        self.sessions.down = True
        response = self.client.get("/api/books", headers=as_customer())
        self.assert_error(response, 503, "The login service is not answering. Please try again in a moment.")

    # ------------------------------------------------------------ one book (FR6)

    def test_get_returns_one_book(self):
        response = self.client.get(f"/api/books/{self.effective_java.id}", headers=as_customer())
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json()["title"], "Effective Java")

    def test_get_an_unknown_book_is_404(self):
        self.assert_error(self.client.get("/api/books/ffffffffffffffffffffffff", headers=as_customer()), 404, "This book does not exist")
        self.assert_error(self.client.get("/api/books/not-an-id", headers=as_customer()), 404, "This book does not exist")

    # ------------------------------------------------------------ add (FR14)

    def test_a_manager_adds_a_book(self):
        response = self.client.post("/api/books", json=NEW_BOOK, headers=as_manager())
        self.assertEqual(response.status_code, 201)
        created = response.get_json()
        self.assertEqual(created["title"], "Clean Architecture")
        self.assertEqual(created["copiesAvailable"], 3)
        self.assertIsNone(created["coverUrl"])
        self.assertEqual(created["category"], "Technology")
        found = self.client.get("/api/books?keyword=architecture", headers=as_customer()).get_json()
        self.assertEqual([b["id"] for b in found], [created["id"]], "the new book can be found by search")

    def test_adding_a_book_checks_every_field(self):
        cases = [
            ({"title": ""}, "Enter the title"),
            ({"title": None}, "Enter the title"),
            ({"author": "   "}, "Enter the author"),
            ({"title": "x" * 256}, "The title is too long (at most 255 characters)"),
            ({"price": "40"}, "Enter the price as a number"),
            ({"price": True}, "Enter the price as a number"),
            ({"price": 0}, "The price must be greater than 0"),
            ({"price": -5}, "The price must be greater than 0"),
            ({"copiesAvailable": 1.5}, "Enter the number of copies as a whole number"),
            ({"copiesAvailable": -1}, "The number of copies cannot be negative"),
            ({"coverUrl": "javascript:alert(1)"}, "The cover address must start with http:// or https://"),
            ({"category": None}, "Choose a category: Fiction, Nonfiction, Kids, Science, or Technology"),
            ({"category": "Poetry"}, "Choose a category: Fiction, Nonfiction, Kids, Science, or Technology"),
        ]
        for change, message in cases:
            with self.subTest(change=change):
                self.assert_error(self.client.post("/api/books", json={**NEW_BOOK, **change}, headers=as_manager()), 400, message)
        self.assertEqual(len(self.repository.search("")), 4, "no invalid book was stored")

    def test_a_body_that_is_not_json_is_400(self):
        response = self.client.post("/api/books", data="this is not json", headers=as_manager())
        self.assert_error(response, 400, "The request body is not valid JSON")
        self.assert_error(self.client.post("/api/books", json=[1, 2], headers=as_manager()), 400, "Send the book as a JSON object")

    def test_text_is_trimmed_and_the_price_keeps_two_decimals(self):
        body = {**NEW_BOOK, "title": "  Padded  ", "price": 19.999}
        created = self.client.post("/api/books", json=body, headers=as_manager()).get_json()
        self.assertEqual(created["title"], "Padded")
        self.assertEqual(created["price"], 20.0)

    # ------------------------------------------------------------ update (FR14)

    def test_a_manager_updates_the_number_of_copies(self):
        body = {"title": "Clean Code", "author": "Robert C. Martin", "price": 40.0, "copiesAvailable": 10, "category": "Science"}
        response = self.client.put(f"/api/books/{self.clean_code.id}", json=body, headers=as_manager())
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json()["copiesAvailable"], 10)
        self.assertEqual(response.get_json()["category"], "Science", "the shelf can be changed too")
        self.assertEqual(self.repository.find(self.clean_code.id).copies_available, 10)

    def test_updating_an_unknown_book_is_404_and_a_bad_field_is_400(self):
        self.assert_error(self.client.put("/api/books/ffffffffffffffffffffffff", json=NEW_BOOK, headers=as_manager()), 404, "This book does not exist")
        response = self.client.put(f"/api/books/{self.clean_code.id}", json={**NEW_BOOK, "price": 0}, headers=as_manager())
        self.assert_error(response, 400, "The price must be greater than 0")

    # ------------------------------------------------------------ copies (order-service only)

    def service(self):
        return {"X-Service-Key": SERVICE_KEY}

    def test_order_service_takes_a_copy(self):
        response = self.client.patch(f"/api/books/{self.clean_code.id}/copies", json={"change": -1}, headers=self.service())
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json()["copiesAvailable"], 3)

    def test_the_copies_endpoint_is_closed_to_the_apps(self):
        url = f"/api/books/{self.clean_code.id}/copies"
        message = "This address is for the bookstore's own services only"
        self.assert_error(self.client.patch(url, json={"change": -1}), 403, message)
        self.assert_error(self.client.patch(url, json={"change": -1}, headers={"X-Service-Key": "wrong"}), 403, message)
        self.assert_error(self.client.patch(url, json={"change": -1}, headers=as_manager()), 403, message)
        self.assertEqual(self.repository.find(self.clean_code.id).copies_available, 4, "nothing was taken")

    def test_copies_cannot_go_below_zero(self):
        sold_out = self.client.patch(f"/api/books/{self.sold_out.id}/copies", json={"change": -1}, headers=self.service())
        self.assert_error(sold_out, 409, '"MongoDB: The Definitive Guide" is not available')
        too_many = self.client.patch(f"/api/books/{self.effective_java.id}/copies", json={"change": -3}, headers=self.service())
        self.assert_error(too_many, 409, 'Only 2 of "Effective Java" left')
        self.assertEqual(self.repository.find(self.effective_java.id).copies_available, 2)

    def test_copies_of_an_unknown_book_is_404_and_a_bad_change_is_400(self):
        self.assert_error(self.client.patch("/api/books/ffffffffffffffffffffffff/copies", json={"change": -1}, headers=self.service()), 404, "This book does not exist")
        for bad in [{"change": 0}, {"change": "one"}, {"change": 1.5}, {}]:
            with self.subTest(body=bad):
                response = self.client.patch(f"/api/books/{self.clean_code.id}/copies", json=bad, headers=self.service())
                self.assert_error(response, 400, "Enter the change as a whole number other than 0")

    def test_with_no_service_key_configured_the_endpoint_stays_closed(self):
        client = create_app(self.repository, self.sessions, "").test_client()
        response = client.patch(f"/api/books/{self.clean_code.id}/copies", json={"change": -1}, headers={"X-Service-Key": ""})
        self.assertEqual(response.status_code, 403)

    # ------------------------------------------------------------ wrong address or method

    def test_unknown_addresses_and_wrong_methods_answer_in_json(self):
        self.assert_error(self.client.get("/api/nothing"), 404, "There is nothing at this address")
        self.assert_error(self.client.delete(f"/api/books/{self.clean_code.id}", headers=as_manager()), 405, "This address does not accept that kind of request")


if __name__ == "__main__":
    unittest.main()
