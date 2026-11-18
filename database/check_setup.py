"""Say whether this computer's databases are ready for the services, in plain words.

Run:  python database/check_setup.py
Exit code: 0 ready; 2 the MySQL account or tables are missing; 3 MongoDB is not
answering; 4 services/.env is missing. setup.cmd uses the code to decide what to do.
Prints no password.
"""
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def main() -> int:
    env_file = ROOT / "services" / ".env"
    if not env_file.exists():
        print("services/.env is missing (run python database/make_local_setup.py)")
        return 4
    for line in env_file.read_text(encoding="utf-8").splitlines():
        if "=" in line and not line.lstrip().startswith("#"):
            name, value = line.split("=", 1)
            os.environ.setdefault(name.strip(), value.strip())

    import mysql.connector
    from pymongo import MongoClient
    from pymongo.errors import PyMongoError

    try:
        db = mysql.connector.connect(
            host=os.getenv("MYSQL_HOST", "localhost"),
            user=os.getenv("MYSQL_USER"),
            password=os.getenv("MYSQL_PASSWORD", ""),
            database=os.getenv("MYSQL_DATABASE", "bookstore"),
            connection_timeout=5,
        )
        cursor = db.cursor()
        cursor.execute("SHOW TABLES")
        tables = {row[0] for row in cursor.fetchall()}
        db.close()
    except mysql.connector.Error as error:
        print(f"MySQL: the services' account cannot log in yet ({error.msg})")
        return 2
    missing = {"users", "sessions", "orders", "order_items"} - tables
    if missing:
        print(f"MySQL: tables missing: {', '.join(sorted(missing))}")
        return 2
    print(f"MySQL: ready (account {os.getenv('MYSQL_USER')}, {len(tables)} tables)")

    try:
        client = MongoClient(os.getenv("MONGO_URL", "mongodb://localhost:27017"), serverSelectionTimeoutMS=3000)
        books = client[os.getenv("MONGO_DATABASE", "bookstore")]["books"].count_documents({})
    except PyMongoError:
        print("MongoDB: not answering on " + os.getenv("MONGO_URL", "mongodb://localhost:27017"))
        return 3
    print(f"MongoDB: ready ({books} books)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
