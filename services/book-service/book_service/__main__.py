"""Starts book-service:  python -m book_service  (from services/book-service)."""
import logging

from waitress import serve

from .app import create_production_app
from .config import Config


def main() -> None:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
    config = Config.load()
    app = create_production_app(config)
    if not config.service_key:
        logging.warning("SERVICE_KEY is not set: the copies endpoint will refuse every request")

    # Both loopback addresses, and only those: "localhost" can mean either, and listening on
    # one alone made the first request wait about two seconds (problem P-004). Nothing outside
    # this machine can connect.
    listen = f"127.0.0.1:{config.port} [::1]:{config.port}"
    logging.info("book-service is listening on http://localhost:%s", config.port)
    serve(app, listen=listen, threads=8, ident="book-service")


if __name__ == "__main__":
    main()
