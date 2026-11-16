"""Errors that are safe to show to the caller, and the one place that turns them into responses.

Routes and services simply raise. `register_error_handlers` makes sure every
failure, expected or not, is answered as `{"error": "message"}` with a
sensible status, and that an unexpected failure is logged in full but
answered without any details.

The same as book-service's errors.py on purpose: each service is its own
project and can be run alone, so the two do not share code.
"""
import logging

from flask import Flask, jsonify
from werkzeug.exceptions import HTTPException

log = logging.getLogger(__name__)


class ApiError(Exception):
    """An error with an HTTP status and a message written for a person."""

    status = 500

    def __init__(self, message: str):
        super().__init__(message)
        self.message = message


class ValidationError(ApiError):
    """400: the request is missing a field, or a value is not acceptable. The message names the field."""

    status = 400


class UnauthorizedError(ApiError):
    """401: the caller is not logged in, or the session has ended."""

    status = 401


class ForbiddenError(ApiError):
    """403: the caller is logged in, but may not do this (N5)."""

    status = 403


class NotFoundError(ApiError):
    """404: the order or the book does not exist."""

    status = 404


class ConflictError(ApiError):
    """409: the request is valid but cannot be done now: a book has no copies available."""

    status = 409


class ServiceUnavailableError(ApiError):
    """503: something this service depends on (user-service, book-service, MySQL) is not answering."""

    status = 503


def register_error_handlers(app: Flask) -> None:
    """Make `app` answer every error in the one agreed shape."""

    @app.errorhandler(ApiError)
    def handle_api_error(error: ApiError):
        return jsonify(error=error.message), error.status

    @app.errorhandler(HTTPException)
    def handle_http_error(error: HTTPException):
        # Flask's own errors: unknown address, wrong method, a body that is not JSON.
        messages = {
            400: "The request body is not valid JSON",
            404: "There is nothing at this address",
            405: "This address does not accept that kind of request",
            415: "Send the request body as JSON (Content-Type: application/json)",
        }
        return jsonify(error=messages.get(error.code, error.name)), error.code or 500

    @app.errorhandler(Exception)
    def handle_unexpected(error: Exception):
        # A bug or a failed database. Full details go to the log, none to the caller.
        log.exception("Unexpected error")
        return jsonify(error="Something went wrong on the server. Please try again."), 500
