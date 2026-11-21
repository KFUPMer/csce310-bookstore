# Phase 2 — Database design

> Status: **final**. Every column, field, type, and link, read from the schema and the code, is in section 1 of the course report ([docs/07-report](../07-report/sections/1-database.html)).

## Diagram

![Database ER and document model](diagrams/database-er.png)

Source: [diagrams/database-er.drawio](diagrams/database-er.drawio)

## MySQL

| Table | Purpose | Requirements |
|---|---|---|
| `USERS` | Accounts with username, email, hashed password, and role (`CUSTOMER` or `MANAGER`) | FR1, FR3, FR11 |
| `SESSIONS` | One row per logged-in session; deleted on logout | FR2 |
| `ORDERS` | One row per order, with total and payment status (`PENDING` or `PAID`) | FR7, FR8, FR12, FR13 |
| `ORDER_ITEMS` | The books in an order, each with its type (`BUY` or `RENT`), the price charged, and a due date if rented | FR6, FR7, FR8 |

## MongoDB

Collection `books` (FR4, FR5, FR14):

```json
{
  "_id": "ObjectId",
  "title": "Example Title",
  "author": "Author Name",
  "price": 19.99,
  "copiesAvailable": 12,
  "coverUrl": "https://covers.openlibrary.org/b/id/8065615-L.jpg",
  "category": "Technology"
}
```

Collection `reviews` (course section-6 extra credit; one review per customer per book, held by the unique index `one_review_per_customer_per_book` on `bookId` + `userId`):

```json
{
  "_id": "ObjectId",
  "bookId": "the book's _id, as a string",
  "userId": 3,
  "username": "alice",
  "rating": 4,
  "text": "A practical book.",
  "createdAt": "date",
  "updatedAt": "date"
}
```

A book's `ratingAverage` and `ratingCount` are worked out from its reviews on every search; they are never stored.

## Notes

- `coverUrl` is optional: the address of a cover image. When it is missing or `null`, the apps draw a cover from the title (see [style-guide.md](style-guide.md)).
- `ORDER_ITEMS.book_id` points to a MongoDB document, so there is no foreign key across databases. order-service checks the book through book-service.
- `reviews.userId` is a MySQL user id: another link across databases, kept correct by book-service, which takes the id from user-service's answer about the session token.
- `title`, `author`, and `unit_price` are copied into the order item, so the bill stays correct even if the book is changed later.
- Renting costs 10% of the book price and lasts 7 days. Books have no separate rent price: order-service calculates it, so for a `RENT` item `unit_price` = 10% of the book price and `rent_due_date` = order date + 7 days. For a `BUY` item `rent_due_date` is empty.

## Scripts

- [x] SQL schema script — [database/mysql/schema.sql](../../database/mysql/schema.sql)
- [x] Seed data, required by the PRD for testing — [database/seed.py](../../database/seed.py) and [books.json](../../database/mongodb/books.json): 81 books on 5 shelves, one customer, one manager; [demo_data.py](../../database/demo_data.py) adds 14 demo customers, 100 past sales, and reviews
- [x] Indexes on `title` and `author` — created by the seed script; the unique review index — created by book-service on start
- [x] Run against the real databases (M3): MySQL 8.0 and MongoDB, used by all three services
