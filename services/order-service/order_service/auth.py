"""Who is making this request, and are they allowed to?

Accounts and sessions belong to user-service, so this service asks it
(N4, N5). `SessionChecker` is the interface; `UserServiceSessionChecker` is
the real one; tests use a fake. The same approach as book-service's auth.py.
"""
from abc import ABC, abstractmethod

import requests

from .errors import ForbiddenError, ServiceUnavailableError, UnauthorizedError
from .models import CurrentUser

NOT_LOGGED_IN = "You are not logged in"
LOGIN_SERVICE_DOWN = "The login service is not answering. Please try again in a moment."
BEARER = "Bearer "

# How long to wait for user-service before giving up, in seconds: (to connect, to answer).
TIMEOUT = (2, 3)


class SessionChecker(ABC):
    @abstractmethod
    def check(self, token: str) -> CurrentUser:
        """Who this token belongs to. Raises UnauthorizedError if it is not a current session."""


class UserServiceSessionChecker(SessionChecker):
    """Asks user-service: GET /api/auth/session."""

    def __init__(self, user_service_url: str):
        self._url = user_service_url + "/api/auth/session"
        # One Session object reuses its connection, which saves time on every request (N1).
        self._http = requests.Session()

    def check(self, token: str) -> CurrentUser:
        try:
            response = self._http.get(self._url, headers={"Authorization": BEARER + token}, timeout=TIMEOUT)
        except requests.RequestException as error:
            # user-service is down or too slow. Say so, rather than hang or pretend the user is logged out.
            raise ServiceUnavailableError(LOGIN_SERVICE_DOWN) from error

        if response.status_code == 401:
            raise UnauthorizedError(self._message(response, "Your session has ended. Please log in again."))
        if response.status_code != 200:
            raise ServiceUnavailableError(LOGIN_SERVICE_DOWN)
        try:
            body = response.json()
            return CurrentUser(user_id=body["userId"], username=body["username"], email=body["email"], role=body["role"])
        except (ValueError, KeyError, TypeError) as error:
            # Something answered on user-service's port, but not with what user-service says.
            raise ServiceUnavailableError(LOGIN_SERVICE_DOWN) from error

    @staticmethod
    def _message(response: requests.Response, fallback: str) -> str:
        try:
            return response.json().get("error") or fallback
        except (ValueError, AttributeError):
            return fallback


def token_from(authorization_header: str | None) -> str:
    """The token in an `Authorization: Bearer <token>` header. Raises UnauthorizedError if there is none."""
    if not authorization_header or not authorization_header.startswith(BEARER) or len(authorization_header) == len(BEARER):
        raise UnauthorizedError(NOT_LOGGED_IN)
    return authorization_header[len(BEARER):].strip()


def require_customer(user: CurrentUser) -> None:
    """N5: only a customer places orders."""
    if not user.is_customer:
        raise ForbiddenError("Only a customer can place an order")


def require_manager(user: CurrentUser) -> None:
    """N5: only a manager lists all orders and changes the payment status."""
    if not user.is_manager:
        raise ForbiddenError("Only a manager can do this")
