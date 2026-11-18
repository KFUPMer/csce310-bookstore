"""The endpoints under /api/books, including a book's reviews.

Each one: find out who is asking, check the request, call the service, return
JSON. No rules live here, and no error responses are built here: routes raise,
and errors.py answers.
"""
from flask import Blueprint, jsonify, request

from .auth import SessionChecker, require_customer, require_manager, require_service_key, token_from
from .models import CurrentUser
from .schemas import BookInput, CopiesChange, ReviewInput, category_filter
from .services import BookService, ReviewService

SERVICE_KEY_HEADER = "X-Service-Key"


def create_routes(books: BookService, reviews: ReviewService, sessions: SessionChecker, service_key: str) -> Blueprint:
    routes = Blueprint("books", __name__, url_prefix="/api/books")

    def current_user() -> CurrentUser:
        """N4: every endpoint for the apps needs a valid session token."""
        return sessions.check(token_from(request.headers.get("Authorization")))

    def json_body():
        # silent=False: a body that is not JSON becomes a 400 through errors.py.
        return request.get_json(force=True, silent=False)

    @routes.get("")
    def search():
        """GET /api/books?keyword=&category= (FR4, FR5; the category is beyond the PRD). Any logged-in user."""
        current_user()
        found = books.search(request.args.get("keyword", ""), category_filter(request.args.get("category")))
        return jsonify([book.to_json() for book in found])

    @routes.get("/<book_id>")
    def get(book_id: str):
        """GET /api/books/{id} (FR6). Any logged-in user."""
        current_user()
        return jsonify(books.get(book_id).to_json())

    @routes.post("")
    def add():
        """POST /api/books (FR14). Managers only."""
        require_manager(current_user())
        book = books.add(BookInput.from_json(json_body()))
        return jsonify(book.to_json()), 201

    @routes.put("/<book_id>")
    def update(book_id: str):
        """PUT /api/books/{id} (FR14). Managers only."""
        require_manager(current_user())
        book = books.update(book_id, BookInput.from_json(json_body()))
        return jsonify(book.to_json())

    @routes.patch("/<book_id>/copies")
    def change_copies(book_id: str):
        """PATCH /api/books/{id}/copies. For order-service only: takes copies when an order is placed."""
        require_service_key(request.headers.get(SERVICE_KEY_HEADER), service_key)
        change = CopiesChange.from_json(json_body())
        return jsonify(books.change_copies(book_id, change.change).to_json())

    @routes.get("/<book_id>/reviews")
    def list_reviews(book_id: str):
        """GET /api/books/{id}/reviews (extra credit). Any logged-in user."""
        current_user()
        return jsonify([review.to_json() for review in reviews.list_for_book(book_id)])

    @routes.put("/<book_id>/reviews/mine")
    def save_my_review(book_id: str):
        """PUT /api/books/{id}/reviews/mine (extra credit). Customers only: writes or replaces their review."""
        user = current_user()
        require_customer(user)
        review = reviews.save_mine(book_id, user, ReviewInput.from_json(json_body()))
        return jsonify(review.to_json())

    @routes.delete("/<book_id>/reviews/mine")
    def delete_my_review(book_id: str):
        """DELETE /api/books/{id}/reviews/mine (extra credit). Customers only."""
        user = current_user()
        require_customer(user)
        reviews.delete_mine(book_id, user)
        return "", 204

    return routes
