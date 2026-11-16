"""Starts order-service:  python -m order_service  (from services/order-service)."""
import logging
import sys

import mysql.connector
from waitress import serve

from .app import create_production_app
from .config import Config
from .repository import POOL_SIZE


def main() -> None:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
    try:
        config = Config.load()
    except ValueError as error:
        logging.error("order-service cannot start: %s (see services/.env)", error)
        sys.exit(1)
    try:
        app = create_production_app(config)
    except mysql.connector.Error as error:
        # The error number and text only; MySQL's message names the account, never the password.
        logging.error("order-service cannot start: MySQL is not reachable (%s). Is MySQL running, and is services/.env filled in?", error)
        sys.exit(1)
    if not config.service_key:
        logging.warning("SERVICE_KEY is not set: book-service will refuse to change copies, so no order can be placed")
    if not config.email_is_configured:
        logging.warning("SMTP_USER and SMTP_PASSWORD are not set: bills are saved but not emailed")

    # Both loopback addresses, and only those: "localhost" can mean either, and listening on
    # one alone made the first request wait about two seconds (problem P-004). Nothing outside
    # this machine can connect.
    listen = f"127.0.0.1:{config.port} [::1]:{config.port}"
    logging.info("order-service is listening on http://localhost:%s, bills are saved in %s", config.port, config.bills_folder)
    # One database connection per request thread (see repository.POOL_SIZE).
    serve(app, listen=listen, threads=POOL_SIZE, ident="order-service")


if __name__ == "__main__":
    main()
