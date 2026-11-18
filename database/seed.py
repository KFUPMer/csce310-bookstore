"""Load test data into MySQL and MongoDB.

The PRD requires the book database to be initialized for testing. This script:
  1. creates two test accounts in MySQL (one customer, one manager), with bcrypt-hashed passwords
  2. loads the sample books into MongoDB and creates the search indexes

Run schema.sql first, then:

    pip install bcrypt mysql-connector-python pymongo
    python database/seed.py

Connection settings come from services/.env (written by make_local_setup.py), or
from environment variables of the same names:
    MYSQL_HOST  MYSQL_USER  MYSQL_PASSWORD  MYSQL_DATABASE  MONGO_URL
"""
import json
import os
from pathlib import Path

import bcrypt
import mysql.connector
from pymongo import ASCENDING, MongoClient


def load_env_file():
    """Use the settings in services/.env unless they are already set in the environment."""
    env_file = Path(__file__).resolve().parent.parent / "services" / ".env"
    if not env_file.exists():
        return
    for line in env_file.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            name, value = line.split("=", 1)
            os.environ.setdefault(name.strip(), value.strip())


# Test accounts. For local testing only; never reuse these passwords anywhere real.
TEST_USERS = [
    ("customer1", "customer1@example.com", "customer123", "CUSTOMER"),
    ("manager1", "manager1@example.com", "manager123", "MANAGER"),
]


def seed_users():
    db = mysql.connector.connect(
        host=os.getenv("MYSQL_HOST", "localhost"),
        user=os.getenv("MYSQL_USER", "root"),
        password=os.getenv("MYSQL_PASSWORD", ""),
        database=os.getenv("MYSQL_DATABASE", "bookstore"),
    )
    cur = db.cursor()
    for username, email, password, role in TEST_USERS:
        # prefix 2a so the hash is accepted by both Python and Java bcrypt libraries;
        # rounds=10 is the same cost user-service uses, which keeps login well under 500 ms (N1)
        hashed = bcrypt.hashpw(password.encode(), bcrypt.gensalt(rounds=10, prefix=b"2a")).decode()
        cur.execute(
            "INSERT INTO users (username, email, password_hash, role) VALUES (%s, %s, %s, %s) "
            "ON DUPLICATE KEY UPDATE email = VALUES(email), password_hash = VALUES(password_hash), role = VALUES(role)",
            (username, email, hashed, role),
        )
    db.commit()
    db.close()
    print(f"MySQL: {len(TEST_USERS)} test users ready")


def seed_books():
    books = json.loads((Path(__file__).parent / "mongodb" / "books.json").read_text(encoding="utf-8"))
    collection = MongoClient(os.getenv("MONGO_URL", "mongodb://localhost:27017"))["bookstore"]["books"]
    collection.delete_many({})
    collection.insert_many(books)
    collection.create_index([("title", ASCENDING)])
    collection.create_index([("author", ASCENDING)])
    print(f"MongoDB: {len(books)} books loaded")


def is_seeded() -> bool:
    """True when the test accounts and the books are already there."""
    db = mysql.connector.connect(
        host=os.getenv("MYSQL_HOST", "localhost"),
        user=os.getenv("MYSQL_USER", "root"),
        password=os.getenv("MYSQL_PASSWORD", ""),
        database=os.getenv("MYSQL_DATABASE", "bookstore"),
    )
    cur = db.cursor()
    cur.execute("SELECT COUNT(*) FROM users WHERE username IN (%s, %s)", tuple(u[0] for u in TEST_USERS))
    users = cur.fetchone()[0]
    db.close()
    books = MongoClient(os.getenv("MONGO_URL", "mongodb://localhost:27017"))["bookstore"]["books"].count_documents({})
    return users == len(TEST_USERS) and books > 0


if __name__ == "__main__":
    import sys

    load_env_file()
    # --if-empty: used by setup.cmd, so running setup again never resets data that is already there.
    if "--if-empty" in sys.argv and is_seeded():
        print("Test data already there: left as it is (run without --if-empty to reset it)")
    else:
        seed_users()
        seed_books()
