"""The books, which belong to book-service.

Placing an order needs two things from book-service: the book's details at
this moment, and one copy less on the shelf. Its copies endpoint does both in
one atomic step and answers with the book, so one call per book is enough and
two customers can never both get the last copy.

`BookCatalog` is the interface; `BookServiceCatalog` is the real one; tests
use a fake.
"""
import logging
from abc import ABC, abstractmethod
from decimal import Decimal

import requests

from .errors import ConflictError, NotFoundError, ServiceUnavailableError
from .models import CatalogBook

log = logging.getLogger(__name__)

SERVICE_KEY_HEADER = "X-Service-Key"
CATALOG_DOWN = "The book catalog is not answering. Please try again in a moment."

# How long to wait for book-service before giving up, in seconds: (to connect, to answer).
TIMEOUT = (2, 3)


class BookCatalog(ABC):
    @abstractmethod
    def take(self, book_id: str, quantity: int) -> CatalogBook:
        """Take `quantity` copies of a book off the shelf and return the book.

        Raises NotFoundError if there is no such book and ConflictError if there are not
        enough copies; in both cases nothing was taken."""

    @abstractmethod
    def give_back(self, book_id: str, quantity: int) -> None:
        """Put copies back, when the order they were taken for could not be completed."""


class BookServiceCatalog(BookCatalog):
    """Calls book-service: PATCH /api/books/{id}/copies, with the key the services share."""

    def __init__(self, book_service_url: str, service_key: str):
        self._url = book_service_url + "/api/books/"
        self._http = requests.Session()  # reuses its connection (N1)
        self._http.headers[SERVICE_KEY_HEADER] = service_key

    def take(self, book_id: str, quantity: int) -> CatalogBook:
        return self._change(book_id, -quantity)

    def give_back(self, book_id: str, quantity: int) -> None:
        self._change(book_id, quantity)

    def _change(self, book_id: str, change: int) -> CatalogBook:
        try:
            response = self._http.patch(f"{self._url}{book_id}/copies", json={"change": change}, timeout=TIMEOUT)
        except requests.ConnectionError as error:
            raise ServiceUnavailableError(CATALOG_DOWN) from error  # could not connect: nothing changed
        except requests.RequestException as error:
            # The request went out but no answer came back in time: book-service may or may not
            # have made the change. This cannot be undone safely from here, so it is recorded
            # for a person to check (see "Known gaps" in the problem log).
            log.error("No answer from book-service to a change of %+d copies of book %s: its number of copies may now be wrong", change, book_id)
            raise ServiceUnavailableError(CATALOG_DOWN) from error

        if response.status_code == 404:
            raise NotFoundError(self._message(response, "This book does not exist"))
        if response.status_code == 409:
            raise ConflictError(self._message(response, "This book is not available"))
        if response.status_code != 200:
            # Most likely SERVICE_KEY differs between the two services (403). That is a set-up
            # fault, not something the customer did, so they are told to try later.
            log.error("book-service answered %s to a copies change", response.status_code)
            raise ServiceUnavailableError(CATALOG_DOWN)
        try:
            book = response.json()
            # str() first: Decimal(40.1) would carry the float's rounding error into the money.
            return CatalogBook(id=book["id"], title=book["title"], author=book["author"], price=Decimal(str(book["price"])))
        except (ValueError, KeyError, TypeError, ArithmeticError) as error:
            raise ServiceUnavailableError(CATALOG_DOWN) from error

    @staticmethod
    def _message(response: requests.Response, fallback: str) -> str:
        try:
            return response.json().get("error") or fallback
        except (ValueError, AttributeError):
            return fallback
