"""The service's settings.

Read from environment variables first, then from `services/.env`, then
defaults. Nothing secret is written in the code, and `.env` is ignored by git.
"""
import os
from dataclasses import dataclass, field
from pathlib import Path

SERVICE_FOLDER = Path(__file__).resolve().parents[1]  # services/order-service


def _read_env_file() -> dict:
    """NAME=value lines from services/.env, if it exists. Lines starting with # are comments."""
    path = SERVICE_FOLDER.parent / ".env"
    values = {}
    if path.is_file():
        for line in path.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                name, value = line.split("=", 1)
                values[name.strip()] = value.strip()
    return values


@dataclass(frozen=True)
class Config:
    """Secrets are marked repr=False, so printing or logging a Config never shows them."""

    port: int
    mysql_host: str
    mysql_user: str
    mysql_password: str = field(repr=False)
    mysql_database: str
    user_service_url: str
    book_service_url: str
    service_key: str = field(repr=False)
    """Shared by the services. Lets this service change a book's copies in book-service."""
    bills_folder: Path
    smtp_host: str
    smtp_port: int
    smtp_user: str
    smtp_password: str = field(repr=False)
    mail_from: str

    @property
    def email_is_configured(self) -> bool:
        return bool(self.smtp_host and self.smtp_user and self.smtp_password)

    @staticmethod
    def load() -> "Config":
        file = _read_env_file()

        def value(name: str, fallback: str) -> str:
            return os.environ.get(name) or file.get(name) or fallback

        def number(name: str, fallback: str) -> int:
            try:
                return int(value(name, fallback))
            except ValueError:
                # Names the setting, and does not repeat its value.
                raise ValueError(f"The setting {name} must be a whole number") from None

        smtp_user = value("SMTP_USER", "")
        return Config(
            port=number("ORDER_SERVICE_PORT", "8083"),
            mysql_host=value("MYSQL_HOST", "localhost"),
            mysql_user=value("MYSQL_USER", "root"),
            mysql_password=value("MYSQL_PASSWORD", ""),
            mysql_database=value("MYSQL_DATABASE", "bookstore"),
            user_service_url=value("USER_SERVICE_URL", "http://127.0.0.1:8081").rstrip("/"),
            book_service_url=value("BOOK_SERVICE_URL", "http://127.0.0.1:8082").rstrip("/"),
            service_key=value("SERVICE_KEY", ""),
            bills_folder=Path(value("BILLS_FOLDER", str(SERVICE_FOLDER / "bills"))),
            smtp_host=value("SMTP_HOST", "smtp.gmail.com"),
            smtp_port=number("SMTP_PORT", "587"),
            smtp_user=smtp_user,
            smtp_password=value("SMTP_PASSWORD", ""),
            mail_from=value("MAIL_FROM", smtp_user),
        )
