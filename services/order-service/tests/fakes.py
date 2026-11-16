"""Stand-ins used by the tests in place of user-service, book-service, and the mail server."""
from decimal import Decimal

from order_service.auth import SessionChecker
from order_service.catalog import BookCatalog
from order_service.errors import ConflictError, NotFoundError, ServiceUnavailableError, UnauthorizedError
from order_service.mailer import Mailer
from order_service.models import CatalogBook, CurrentUser, Order

ALICE_TOKEN = "alice-token"
OMAR_TOKEN = "omar-token"
MANAGER_TOKEN = "manager-token"

ALICE = CurrentUser(1, "alice", "alice@example.com", "CUSTOMER")
BOSS = CurrentUser(2, "boss", "boss@example.com", "MANAGER")
OMAR = CurrentUser(3, "omar", "omar@example.com", "CUSTOMER")


class FakeSessionChecker(SessionChecker):
    """Knows three tokens: two customers and a manager. Can be switched 'down'."""

    def __init__(self):
        self.down = False
        self._users = {ALICE_TOKEN: ALICE, OMAR_TOKEN: OMAR, MANAGER_TOKEN: BOSS}

    def check(self, token: str) -> CurrentUser:
        if self.down:
            raise ServiceUnavailableError("The login service is not answering. Please try again in a moment.")
        if token not in self._users:
            raise UnauthorizedError("Your session has ended. Please log in again.")
        return self._users[token]


class FakeCatalog(BookCatalog):
    """Books and their copies in memory. Answers like book-service does, with the same messages."""

    def __init__(self):
        self.down = False
        self._books: dict[str, CatalogBook] = {}
        self.copies: dict[str, int] = {}

    def add(self, number: int, title: str, author: str, price: str, copies: int) -> str:
        book_id = f"{number:024x}"
        self._books[book_id] = CatalogBook(book_id, title, author, Decimal(price))
        self.copies[book_id] = copies
        return book_id

    def take(self, book_id: str, quantity: int) -> CatalogBook:
        if self.down:
            raise ServiceUnavailableError("The book catalog is not answering. Please try again in a moment.")
        if book_id not in self._books:
            raise NotFoundError("This book does not exist")
        if self.copies[book_id] < quantity:
            raise ConflictError(f'"{self._books[book_id].title}" is not available')
        self.copies[book_id] -= quantity
        return self._books[book_id]

    def give_back(self, book_id: str, quantity: int) -> None:
        self.copies[book_id] += quantity


class RecordingMailer(Mailer):
    """Remembers what it was asked to send. Can be switched 'broken' to act like a mailer that crashes."""

    def __init__(self):
        self.broken = False
        self.sent: list[tuple[Order, str]] = []

    def send_bill(self, order: Order, bill_html: str) -> bool:
        if self.broken:
            raise RuntimeError("mail is broken")
        self.sent.append((order, bill_html))
        return True


def as_alice() -> dict:
    return {"Authorization": f"Bearer {ALICE_TOKEN}"}


def as_omar() -> dict:
    return {"Authorization": f"Bearer {OMAR_TOKEN}"}


def as_manager() -> dict:
    return {"Authorization": f"Bearer {MANAGER_TOKEN}"}
