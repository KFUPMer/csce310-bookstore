"""Load test data into MySQL and MongoDB.

The PRD requires the book database to be initialized for testing. This script:
  1. creates two test accounts in MySQL (one customer, one manager), with bcrypt-hashed passwords
  2. loads the sample books into MongoDB and creates the search indexes

Run schema.sql first, then:

    pip install bcrypt mysql-connector-python pymongo
    python database/seed.py

Connection settings come from environment variables (defaults in brackets):
    MYSQL_HOST [localhost]  MYSQL_USER [root]  MYSQL_PASSWORD []  MYSQL_DATABASE [bookstore]
    MONGO_URL [mongodb://localhost:27017]

NOT RUN YET: written during the design phase, before the databases were installed.
"""
import json
import os
from pathlib import Path

import bcrypt
import mysql.connector
from pymongo import ASCENDING, MongoClient

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
        # prefix 2a so the hash is accepted by both Python and Java bcrypt libraries
        hashed = bcrypt.hashpw(password.encode(), bcrypt.gensalt(prefix=b"2a")).decode()
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


if __name__ == "__main__":
    seed_users()
    seed_books()
