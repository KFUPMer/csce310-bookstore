"""The service's settings.

Read from environment variables first, then from `services/.env`, then
defaults. Nothing secret is written in the code, and `.env` is ignored by git.
"""
import os
from dataclasses import dataclass
from pathlib import Path


def _read_env_file() -> dict:
    """NAME=value lines from services/.env, if it exists. Lines starting with # are comments."""
    path = Path(__file__).resolve().parents[2] / ".env"
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
    port: int
    mongo_url: str
    mongo_database: str
    user_service_url: str
    service_key: str
    """Shared by the services. Proves a request to a service-only endpoint comes from another service."""

    @staticmethod
    def load() -> "Config":
        file = _read_env_file()

        def value(name: str, fallback: str) -> str:
            return os.environ.get(name) or file.get(name) or fallback

        return Config(
            port=int(value("BOOK_SERVICE_PORT", "8082")),
            mongo_url=value("MONGO_URL", "mongodb://localhost:27017"),
            mongo_database=value("MONGO_DATABASE", "bookstore"),
            user_service_url=value("USER_SERVICE_URL", "http://127.0.0.1:8081").rstrip("/"),
            service_key=value("SERVICE_KEY", ""),
        )
