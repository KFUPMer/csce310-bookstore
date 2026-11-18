"""Demo data, so the sales report, the best sellers, and the star ratings look like a real shop.

Creates invented customers, 100 past orders at random dates over the last 60 days, and
reviews by those customers of books they ordered. Everything is invented and marked as
such: the customers' emails end in @demo.mooneys.example (a reserved example domain),
which is also how this script finds its own data again.

    python database/demo_data.py              load it (does nothing if it is already there)
    python database/demo_data.py --reset      remove the demo data and load it again
    python database/demo_data.py --remove     remove the demo data only

Real orders, real customers, the test accounts, and the books are never changed. The demo
orders do not reduce the books' copies: those stand for what is on the shelf now. The bills
of demo orders are made the first time they are opened (order-service does that).
Same seed, same data: the names, books, and stars repeat on every run; the dates are
counted back from today. Run after seed.py (it needs the books).
"""
import os
import random
import sys
from datetime import datetime, timedelta
from decimal import ROUND_HALF_UP, Decimal
from pathlib import Path

import bcrypt
import mysql.connector
from pymongo import MongoClient

sys.path.insert(0, str(Path(__file__).resolve().parent))
from seed import load_env_file  # noqa: E402  (same settings as seed.py: services/.env)

DOMAIN = "demo.mooneys.example"
DEMO_PASSWORD = "demo12345"  # invented demo accounts only; never reuse it anywhere real
CUSTOMERS = 14
ORDERS = 100
DAYS = 60
SEED = 310

FIRST = ["Sara", "Omar", "Lina", "Yusuf", "Maya", "Adam", "Noor", "Khalid", "Aisha", "Daniel", "Hana", "Faisal",
         "Emma", "Ali", "Layla", "Zaid", "Mariam", "Jonas", "Reem", "Tariq", "Nora", "Sami", "Clara", "Hamza"]
LAST = ["Haddad", "Rahman", "Okafor", "Silva", "Nasser", "Becker", "Khan", "Moreau", "Aziz", "Lindqvist",
        "Farouk", "Tanaka", "Saleh", "Kowalski", "Darwish", "Novak", "Mansour", "Ibrahim"]

PRAISE = {
    5: ["Loved every page.", "One of the best books I have read this year.", "Could not put it down.",
        "Worth every cent. I have already recommended it to friends.", "A book I will read again."],
    4: ["Very good, with a few slow chapters.", "Well written and easy to follow.", "Enjoyed it a lot.",
        "Clear and useful. I learned something on almost every page.", "A solid read; I would buy it again."],
    3: ["Good in parts, but it dragged in the middle.", "Fine, though I expected more.",
        "Some great ideas, some repetition.", "Okay. Worth renting rather than buying."],
    2: ["Not for me. Hard to get into.", "Too long for what it says.", "Disappointing after all the praise."],
    1: ["Could not finish it.", "Not what I expected at all."],
}


def money(value: Decimal) -> Decimal:
    return value.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def connect():
    return mysql.connector.connect(
        host=os.getenv("MYSQL_HOST", "localhost"),
        user=os.getenv("MYSQL_USER", "root"),
        password=os.getenv("MYSQL_PASSWORD", ""),
        database=os.getenv("MYSQL_DATABASE", "bookstore"),
    )


def reviews_collection():
    return MongoClient(os.getenv("MONGO_URL", "mongodb://localhost:27017"))[os.getenv("MONGO_DATABASE", "bookstore")]["reviews"]


def demo_user_ids(cur) -> list[int]:
    cur.execute("SELECT id FROM users WHERE email LIKE %s", (f"%@{DOMAIN}",))
    return [row[0] for row in cur.fetchall()]


def remove(db) -> None:
    cur = db.cursor()
    ids = demo_user_ids(cur)
    if ids:
        reviews_collection().delete_many({"userId": {"$in": ids}})
        marks = ", ".join(["%s"] * len(ids))
        cur.execute(f"DELETE FROM orders WHERE user_id IN ({marks})", ids)  # order_items go with them (ON DELETE CASCADE)
        orders = cur.rowcount
        cur.execute(f"DELETE FROM users WHERE id IN ({marks})", ids)       # their sessions go with them
        db.commit()
        print(f"Removed the demo data: {len(ids)} customers, {orders} orders, and their reviews")
    else:
        print("No demo data to remove")
    cur.close()


def load(db) -> None:
    rng = random.Random(SEED)
    now = datetime.now().replace(microsecond=0)
    books = list(MongoClient(os.getenv("MONGO_URL", "mongodb://localhost:27017"))[os.getenv("MONGO_DATABASE", "bookstore")]["books"].find())
    if len(books) < 10:
        sys.exit("Load the books first: python database/seed.py")
    # Some books sell far more than others, so the report has real best sellers.
    weights = [rng.choice([1, 1, 1, 2, 3, 6]) for _ in books]

    cur = db.cursor()
    hashed = bcrypt.hashpw(DEMO_PASSWORD.encode(), bcrypt.gensalt(rounds=10, prefix=b"2a")).decode()
    names = rng.sample([(f, l) for f in FIRST for l in LAST], CUSTOMERS)
    customers = []
    for first, last in names:
        username = f"{first}.{last}".lower()
        joined = now - timedelta(days=rng.randint(DAYS + 5, DAYS + 200), hours=rng.randint(0, 23))
        cur.execute(
            "INSERT INTO users (username, email, password_hash, role, created_at) VALUES (%s, %s, %s, 'CUSTOMER', %s)",
            (username, f"{username}@{DOMAIN}", hashed, joined),
        )
        customers.append((cur.lastrowid, username))

    bought: dict[tuple[int, str], datetime] = {}  # (customer id, book id) -> when it was ordered
    for _ in range(ORDERS):
        user_id, _name = rng.choice(customers)
        # A random moment in the last 60 days (never in the future), at shop hours.
        placed = now - timedelta(days=rng.randint(0, DAYS - 1))
        placed = placed.replace(hour=rng.randint(9, 21), minute=rng.randint(0, 59), second=rng.randint(0, 59))
        if placed > now:
            placed -= timedelta(days=1)
        lines = []
        for book in {id(b): b for b in rng.choices(books, weights, k=rng.choice([1, 1, 2, 2, 3]))}.values():
            kind = "RENT" if rng.random() < 0.25 else "BUY"
            price = Decimal(str(book["price"]))
            unit = price if kind == "BUY" else money(price * Decimal("0.10"))
            quantity = 2 if kind == "BUY" and rng.random() < 0.1 else 1
            due = (placed + timedelta(days=7)).date() if kind == "RENT" else None
            lines.append((str(book["_id"]), book["title"], book["author"], kind, quantity, unit, due))
        total = sum((unit * quantity for *_, quantity, unit, _due in lines), Decimal("0.00"))
        # Older orders have mostly been paid; recent ones are often still waiting.
        paid = rng.random() < (0.85 if (now - placed).days > 7 else 0.5)
        cur.execute(
            "INSERT INTO orders (user_id, payment_status, total, created_at) VALUES (%s, %s, %s, %s)",
            (user_id, "PAID" if paid else "PENDING", total, placed),
        )
        order_id = cur.lastrowid
        cur.executemany(
            "INSERT INTO order_items (order_id, book_id, title, author, type, quantity, unit_price, rent_due_date) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)",
            [(order_id, *line) for line in lines],
        )
        for line in lines:
            key = (user_id, line[0])
            bought[key] = min(bought.get(key, placed), placed)
    db.commit()

    reviews = []
    names_by_id = dict(customers)
    for (user_id, book_id), first_order in bought.items():
        if rng.random() < 0.6:  # most customers review only some of what they read
            rating = rng.choices([5, 4, 3, 2, 1], [40, 33, 15, 8, 4])[0]
            written = min(first_order + timedelta(days=rng.randint(2, 20), hours=rng.randint(0, 10)), now)
            text = "" if rng.random() < 0.15 else rng.choice(PRAISE[rating])
            reviews.append({"bookId": book_id, "userId": user_id, "username": names_by_id[user_id], "rating": rating,
                            "text": text, "createdAt": written, "updatedAt": written})
    if reviews:
        reviews_collection().insert_many(reviews)

    # Self-check: what was asked for is what is there.
    cur.execute(f"SELECT COUNT(*) FROM orders WHERE user_id IN ({', '.join(['%s'] * len(customers))})", [c[0] for c in customers])
    assert cur.fetchone()[0] == ORDERS, "every demo order was saved"
    assert all((r["userId"], r["bookId"]) in bought for r in reviews), "a review only of a book its writer ordered"
    cur.close()
    print(f"Loaded the demo data: {CUSTOMERS} customers (password {DEMO_PASSWORD}), {ORDERS} orders over the last {DAYS} days, {len(reviews)} reviews")


def main() -> None:
    load_env_file()
    db = connect()
    try:
        if "--remove" in sys.argv or "--reset" in sys.argv:
            remove(db)
            if "--remove" in sys.argv:
                return
        cur = db.cursor()
        already = demo_user_ids(cur)
        cur.close()
        if already:
            print(f"Demo data already there ({len(already)} customers): kept. Use --reset to load it again.")
            return
        load(db)
    finally:
        db.close()


if __name__ == "__main__":
    main()
