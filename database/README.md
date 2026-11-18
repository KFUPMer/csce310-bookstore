# Database setup

| File | What it is |
|---|---|
| [mysql/schema.sql](mysql/schema.sql) | Creates the `bookstore` database and its four tables |
| [mongodb/books.json](mongodb/books.json) | 27 sample books (title, author, price, copies, shelf, cover photo address) |
| [make_local_setup.py](make_local_setup.py) | Generates the local setup: a dedicated MySQL account and `services/.env` |
| [seed.py](seed.py) | Creates the test accounts and loads the books. `--if-empty` (used by setup.cmd) keeps existing data and only brings it up to date |
| [check_setup.py](check_setup.py) | Says in plain words whether each database is ready |

## Steps

1. Generate this machine's setup: a dedicated MySQL account for the services and the `services/.env` settings file.

```bash
python database/make_local_setup.py
```

2. Create the database, tables, and that account. Run in Command Prompt; it asks for the MySQL root password.

```bash
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p < database\mysql\setup.local.sql
```

3. Load the test accounts and the books.

```bash
python database/seed.py
```

## Test data

- **Accounts:** one customer (`customer1`) and one manager (`manager1`). Their test passwords are at the top of `seed.py`.
- **Books:** 27 titles on five shelves: 15 Technology (the original computing books), and 3 each of Fiction, Nonfiction, Kids, and Science, added so every shelf has books. One has 0 copies, to test the "not available" case; two share an author, to test searching by author.
- **Covers:** each book links to its cover photo on Open Library (https://openlibrary.org), checked by eye for the right title and edition. The photos are not stored here. Without internet the apps draw a cover instead.
- **Upgrading an existing database:** `python database/seed.py --if-empty` adds the books that are missing and gives existing ones a shelf and a cover if they have none. It changes nothing else, so copies and edits made in the manager app are kept.

## Status

- **MongoDB: loaded and checked** on 2026-11-13. 15 books, indexes on title and author, and a search for "java" returns 3 books.
- **MySQL: created and checked** on 2026-11-13. Four tables, the limited `bookstore_app` account, and the two test accounts. user-service logs in with them.

Design: [database-design.md](../docs/02-design/database-design.md).
