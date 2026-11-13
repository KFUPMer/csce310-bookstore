# Database setup

| File | What it is |
|---|---|
| [mysql/schema.sql](mysql/schema.sql) | Creates the `bookstore` database and its four tables |
| [mongodb/books.json](mongodb/books.json) | 15 sample books (title, author, price, copies) |
| [seed.py](seed.py) | Creates the test accounts and loads the books |

## Steps

```bash
mysql -u root -p < database/mysql/schema.sql
```

```bash
pip install bcrypt mysql-connector-python pymongo
```

```bash
python database/seed.py
```

## Test data

- **Accounts:** one customer (`customer1`) and one manager (`manager1`). Their test passwords are at the top of `seed.py`.
- **Books:** 15 titles. One has 0 copies, to test the "not available" case; two share an author, to test searching by author.

## Status

Written during the design phase. **Not run yet**: MySQL and MongoDB are installed in milestone M3, and the scripts will be tested then.

Design: [database-design.md](../docs/02-design/database-design.md).
