"""Puts the parts together.

`create_app` is given the repositories, the session checker and the clock, so
tests can hand it in-memory ones. `create_production_app` builds the real ones
from the settings. This is the only module that knows which concrete classes
are used.
"""
import logging
from datetime import datetime
from typing import Callable

from flask import Flask
from pymongo import MongoClient
from pymongo.errors import PyMongoError

from .auth import SessionChecker, UserServiceSessionChecker
from .config import Config
from .errors import ServiceUnavailableError, register_error_handlers
from .repository import BookRepository, MongoBookRepository, MongoReviewRepository, ReviewRepository
from .routes import create_routes
from .services import BookService, ReviewService

log = logging.getLogger(__name__)

# A request body larger than this is refused by Flask with 413. A book is a few hundred bytes.
MAX_BODY_BYTES = 16 * 1024


def create_app(
    books: BookRepository,
    reviews: ReviewRepository,
    sessions: SessionChecker,
    service_key: str,
    clock: Callable[[], datetime] = datetime.now,
) -> Flask:
    app = Flask(__name__)
    app.config["MAX_CONTENT_LENGTH"] = MAX_BODY_BYTES
    app.json.sort_keys = False  # keep fields in the order of the API specification
    register_error_handlers(app)

    @app.errorhandler(PyMongoError)
    def database_failed(error: PyMongoError):
        # MongoDB is down or a query failed. Details to the log, a plain message to the caller.
        log.exception("MongoDB error")
        unavailable = ServiceUnavailableError("The book catalog is not available right now. Please try again in a moment.")
        return {"error": unavailable.message}, unavailable.status

    routes = create_routes(BookService(books, reviews), ReviewService(books, reviews, clock), sessions, service_key)
    app.register_blueprint(routes)
    return app


def create_production_app(config: Config) -> Flask:
    # serverSelectionTimeoutMS: if MongoDB is down, fail in 3 seconds instead of the default 30.
    client = MongoClient(config.mongo_url, serverSelectionTimeoutMS=3000)
    database = client[config.mongo_database]
    reviews = MongoReviewRepository(database["reviews"])
    try:
        reviews.ensure_indexes()
    except PyMongoError:
        # The service still starts and answers 503 until MongoDB is back, as before reviews existed.
        # The repository creates the index before its first write instead.
        log.warning("Could not reach MongoDB to create the reviews index; it will be created before the first review is saved")
    return create_app(MongoBookRepository(database["books"]), reviews, UserServiceSessionChecker(config.user_service_url), config.service_key)
