"""Stand-ins used by the tests in place of user-service."""
from book_service.auth import SessionChecker
from book_service.errors import ServiceUnavailableError, UnauthorizedError
from book_service.models import CurrentUser

CUSTOMER_TOKEN = "customer-token"
OTHER_CUSTOMER_TOKEN = "other-customer-token"
MANAGER_TOKEN = "manager-token"
SERVICE_KEY = "test-service-key"


class FakeSessionChecker(SessionChecker):
    """Knows two customers and a manager. Can be switched 'down' to act like user-service not answering."""

    def __init__(self):
        self.down = False
        self._users = {
            CUSTOMER_TOKEN: CurrentUser(1, "alice", "alice@example.com", "CUSTOMER"),
            MANAGER_TOKEN: CurrentUser(2, "boss", "boss@example.com", "MANAGER"),
            OTHER_CUSTOMER_TOKEN: CurrentUser(3, "bob", "bob@example.com", "CUSTOMER"),
        }

    def check(self, token: str) -> CurrentUser:
        if self.down:
            raise ServiceUnavailableError("The login service is not answering. Please try again in a moment.")
        if token not in self._users:
            raise UnauthorizedError("Your session has ended. Please log in again.")
        return self._users[token]


def as_customer() -> dict:
    return {"Authorization": f"Bearer {CUSTOMER_TOKEN}"}


def as_other_customer() -> dict:
    return {"Authorization": f"Bearer {OTHER_CUSTOMER_TOKEN}"}


def as_manager() -> dict:
    return {"Authorization": f"Bearer {MANAGER_TOKEN}"}
