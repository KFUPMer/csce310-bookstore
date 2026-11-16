"""Puts the parts together.

`create_app` is given the repository, the book catalog, the session checker,
the bill store, and the mailer, so tests can hand it in-memory ones.
`create_production_app` builds the real ones from the settings. This is the
only module that knows which concrete classes are used.
"""
import logging
from datetime import datetime
from typing import Callable

import mysql.connector
from flask import Flask

from .auth import SessionChecker, UserServiceSessionChecker
from .bill import BillStore
from .catalog import BookCatalog, BookServiceCatalog
from .config import Config
from .errors import ServiceUnavailableError, register_error_handlers
from .mailer import Mailer, NoMailer, SmtpMailer
from .repository import MySqlOrderRepository, OrderRepository, create_pool
from .routes import create_routes
from .services import OrderService

log = logging.getLogger(__name__)

# A request body larger than this is refused by Flask with 413. The largest order is about 4 KB.
MAX_BODY_BYTES = 16 * 1024


def create_app(
    orders: OrderRepository,
    catalog: BookCatalog,
    sessions: SessionChecker,
    bills: BillStore,
    mailer: Mailer,
    clock: Callable[[], datetime] = datetime.now,
) -> Flask:
    app = Flask(__name__)
    app.config["MAX_CONTENT_LENGTH"] = MAX_BODY_BYTES
    app.json.sort_keys = False  # keep fields in the order of the API specification
    register_error_handlers(app)

    @app.errorhandler(mysql.connector.Error)
    def database_failed(error: mysql.connector.Error):
        # MySQL is down or a query failed. Details to the log, a plain message to the caller.
        log.exception("MySQL error")
        unavailable = ServiceUnavailableError("Orders are not available right now. Please try again in a moment.")
        return {"error": unavailable.message}, unavailable.status

    app.register_blueprint(create_routes(OrderService(orders, catalog, bills, mailer, clock), sessions))
    return app


def create_production_app(config: Config) -> Flask:
    """Raises mysql.connector.Error if MySQL cannot be reached."""
    if config.email_is_configured:
        mailer: Mailer = SmtpMailer(config.smtp_host, config.smtp_port, config.smtp_user, config.smtp_password, config.mail_from)
    else:
        mailer = NoMailer()
    return create_app(
        MySqlOrderRepository(create_pool(config)),
        BookServiceCatalog(config.book_service_url, config.service_key),
        UserServiceSessionChecker(config.user_service_url),
        BillStore(config.bills_folder),
        mailer,
    )
