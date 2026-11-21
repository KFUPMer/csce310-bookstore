# Phase 2 — API specification

> Status: **final**. All 20 endpoints are built and tested, and this document matches the code (checked against it on 2026-11-20 for the course report, `docs/07-report`).

## Rules for every endpoint

- Requests and responses are JSON (`Content-Type: application/json`), except the bill, which is HTML.
- Every endpoint except login and register needs the session token (N4):

  ```
  Authorization: Bearer <token>
  ```

- The "Who" of each endpoint is enforced by the service (N5).
- Errors always look like this, with the matching status code:

  ```json
  { "error": "Wrong username or password" }
  ```

| Status | Meaning |
|---|---|
| 200 | OK |
| 201 | Created |
| 204 | Done, nothing to send back (deleting a review) |
| 400 | The request is missing a field or a value is invalid |
| 401 | No token, or the token is not valid (not logged in) |
| 403 | Logged in, but this role is not allowed to do this |
| 404 | The book, order, or review does not exist |
| 409 | Conflict: username or email already used, or no copies available |
| 413 | The body is over 16 KB (book-service and order-service; user-service answers 400 "The request is too large") |

## Overview

| Service | Method | Path | Who | Requirement |
|---|---|---|---|---|
| user | POST | `/api/auth/login` | Anyone | FR1 |
| user | POST | `/api/auth/logout` | Logged in | FR2 |
| user | GET | `/api/auth/session` | Logged in (used by the other services) | FR2, N4, N5 |
| user | POST | `/api/users/register` | Anyone | FR3 |
| book | GET | `/api/books?keyword=` | Logged in | FR4, FR5 |
| book | GET | `/api/books/{id}` | Logged in | FR6 |
| book | POST | `/api/books` | Manager | FR14 |
| book | PUT | `/api/books/{id}` | Manager | FR14 |
| book | PATCH | `/api/books/{id}/copies` | order-service only | FR7 |
| book | GET | `/api/books/{id}/reviews` | Logged in | Reviews and ratings (extra credit, issue #20) |
| book | PUT | `/api/books/{id}/reviews/mine` | Customer | Reviews and ratings (extra credit, issue #20) |
| book | DELETE | `/api/books/{id}/reviews/mine` | Customer | Reviews and ratings (extra credit, issue #20) |
| order | POST | `/api/orders` | Customer | FR6–FR10 |
| order | GET | `/api/orders` | Manager | FR12 |
| order | GET | `/api/orders/mine` | Customer | Account page (beyond the PRD) |
| order | GET | `/api/orders/{id}` | Owner or Manager | FR8, FR12 |
| order | POST | `/api/orders/{id}/pay` | Owner (customer) | Pretend checkout (beyond the PRD) |
| order | GET | `/api/orders/{id}/bill` | Owner or Manager | FR8, FR9 |
| order | PATCH | `/api/orders/{id}/payment-status` | Manager | FR13 |
| order | GET | `/api/reports/sales?from=&to=&top=` | Manager | Sales report (extra credit, issue #21) |

---

## user-service — `http://localhost:8081`

**Status: built, tested (26 tests), and verified against MySQL.** Login answers in 85–255 ms, a session check in 7–19 ms. Listens on this machine only, on both `127.0.0.1` and `::1`.

Also answers `404` for an unknown address and `405` for a wrong HTTP method.

### POST `/api/auth/login`

Request:

```json
{ "username": "customer1", "password": "…" }
```

Response `200`:

```json
{ "token": "9f2c…e1", "userId": 1, "username": "customer1", "email": "customer1@example.com", "role": "CUSTOMER" }
```

Errors: `400` a field is missing · `401` wrong username or password.

### POST `/api/auth/logout`

No body. Response `200`: `{ "message": "Logged out" }`. The session is deleted.

Errors: `401`.

### GET `/api/auth/session`

Checks the token in the `Authorization` header. The apps do not call this; book-service and order-service call it to validate each request.

Response `200`:

```json
{ "userId": 1, "username": "customer1", "email": "customer1@example.com", "role": "CUSTOMER" }
```

Errors: `401` the token is missing or not valid.

### POST `/api/users/register`

Request:

```json
{ "username": "alice", "email": "alice@example.com", "password": "…" }
```

Rules: username 3–50 characters, only letters, digits, dots, dashes, underscores · email must look like an email (stored in lower case) · password at least 8 characters and at most 72 bytes in UTF-8 (bcrypt's limit; accented or non-Latin letters take more than one byte). The password is hashed with bcrypt (N3). The new account always has role `CUSTOMER`.

Response `201`:

```json
{ "userId": 3, "username": "alice", "email": "alice@example.com", "role": "CUSTOMER" }
```

Errors: `400` a field is missing or invalid · `409` username or email already used.

---

## book-service — `http://localhost:8082`

**Status: built, tested (71 tests), and verified on the running service.** Requests answer in 3–38 ms. Reviews (added 2026-11-18): on the running service a review was saved in 15 ms. Also answers `503` when user-service or MongoDB is not available, and `404` / `405` for an unknown address or a wrong method.

A book looks like this everywhere:

```json
{ "id": "655f1c2ab7e4a1d2c3f4a5b6", "title": "Clean Code", "author": "Robert C. Martin", "price": 40.00, "copiesAvailable": 4, "coverUrl": "https://covers.openlibrary.org/b/id/8065615-L.jpg", "category": "Technology", "ratingAverage": 4.3, "ratingCount": 4 }
```

`coverUrl` is optional (the address of a cover image, or `null`). It can be set in POST and PUT. The sample books' covers are photos from Open Library ([REFERENCES.md](../../REFERENCES.md)).

`category` is the book's shelf, one of `Fiction`, `Nonfiction`, `Kids`, `Science`, `Technology` (added in M5 at the owner's request, beyond the PRD). Required in POST and PUT. It is `null` only for a book stored before shelves existed, until a manager gives it one.

`ratingAverage` and `ratingCount` come from the customers' reviews (extra credit, added in M6). `ratingAverage` is the average number of stars to one decimal, a half rounded up (4.25 becomes 4.3), or `null` when nobody has reviewed the book; `ratingCount` is the number of reviews, `0` when there are none. They are worked out from the reviews on every answer (one database query for a whole search) and never stored on the book, so they cannot be set in POST or PUT.

### GET `/api/books?keyword=java&category=Technology`

Returns the books whose **title or author** contains the keyword, ignoring upper and lower case. Without a keyword, returns all books. `category`, optional, keeps only that shelf; empty or missing means every shelf. Sorted by title.

Response `200`:

```json
[
  { "id": "…", "title": "Effective Java", "author": "Joshua Bloch", "price": 50.00, "copiesAvailable": 4, "coverUrl": "…", "category": "Technology", "ratingAverage": 4.5, "ratingCount": 2 },
  { "id": "…", "title": "Head First Java", "author": "Kathy Sierra and Bert Bates", "price": 35.00, "copiesAvailable": 7, "coverUrl": "…", "category": "Technology", "ratingAverage": null, "ratingCount": 0 }
]
```

An empty list `[]` when nothing matches. Errors: `400` an unknown category ("Choose a category: Fiction, Nonfiction, Kids, Science, or Technology") · `401`.

### GET `/api/books/{id}`

Response `200`: one book. Errors: `401` · `404`.

### POST `/api/books` — manager

Request:

```json
{ "title": "Clean Architecture", "author": "Robert C. Martin", "price": 42.00, "copiesAvailable": 3, "category": "Technology" }
```

Rules: title and author not empty, at most 255 characters · price a number greater than 0 (kept to two decimals) · copies a whole number, 0 or more · `coverUrl` optional, must start with `http://` or `https://` · `category` one of the five shelves.

Response `201`: the new book, with its `id`. Errors: `400` · `401` · `403` not a manager.

### PUT `/api/books/{id}` — manager

Request: the same fields as POST. Response `200`: the updated book.

Errors: `400` · `401` · `403` · `404`.

### PATCH `/api/books/{id}/copies` — order-service only

Used when an order is placed. Not for the apps: it needs the header `X-Service-Key`, a secret shared by the services through configuration.

Request:

```json
{ "change": -1 }
```

Response `200`: the updated book. Errors: `400` the change is not a whole number other than 0 · `403` wrong or missing service key · `404` · `409` not enough copies (nothing is changed).

### Reviews and ratings (extra credit)

Added in M6 (issue #20), course section 6. Any logged-in customer may review any book, not only one they bought: checking purchases would make book-service call order-service, which already calls book-service, a loop between the services. One review per customer per book; the customer who wrote it can change or delete it. Managers cannot review, and there is no moderation by managers (left out on purpose).

Reviews are kept in the MongoDB collection `reviews`, with a unique index `one_review_per_customer_per_book` on (`bookId`, `userId`). A review is stored under the book's own id, so the same id sent in capital letters reaches the same review.

A review looks like this:

```json
{ "id": "6560a1f2c3d4e5f6a7b8c9d0", "bookId": "655f1c2ab7e4a1d2c3f4a5b6", "username": "customer1", "rating": 5, "text": "Clear and practical.", "createdAt": "2026-11-18T10:05:00", "updatedAt": "2026-11-18T10:05:00" }
```

`text` is `""` when the customer wrote nothing. The user id stays inside the service; the apps show the username.

### GET `/api/books/{id}/reviews`

Any logged-in user, customer or manager.

Response `200`: the book's reviews, the most recently written or changed first. An empty list `[]` when there are none.

Errors: `401` · `404` "This book does not exist".

### PUT `/api/books/{id}/reviews/mine` — customer

Writes the customer's review of the book, or replaces the one they wrote before (`createdAt` is kept, `updatedAt` changes).

Request:

```json
{ "rating": 5, "text": "Clear and practical." }
```

Rules: `rating` a whole number from 1 to 5 · `text` optional (missing or `null` means no text), trimmed, then at most 1000 characters, counted as Unicode code points (the customer app's counter counts the same way).

Response `200`: the saved review, in the shape above.

Errors, checked in this order:

- `401` no token, or the session has ended.
- `403` a manager: "Only a customer can review books".
- `400` the body is not a JSON object: "Send the book as a JSON object" (the message all book-service bodies share; it reads oddly for a review) · the rating is missing, not a whole number, or not 1 to 5: "Choose a rating from 1 to 5 stars" · `text` is not a string, for example `42`: "Write the review as text" (a message the plan for this endpoint did not list; it was added while building) · the text is too long: "The review can be at most 1000 characters".
- `404` "This book does not exist".

### DELETE `/api/books/{id}/reviews/mine` — customer

Deletes the customer's own review of the book. No body.

Response `204`, with an empty body.

Errors: `401` · `403` a manager: "Only a customer can review books" · `404` "This book does not exist", or "You have not reviewed this book".

---

## order-service — `http://localhost:8083`

**Status: built, tested (117 tests), and verified on the running service.** The first order after a cold start answered in 93 ms; other requests in 6–44 ms. Re-checked on 2026-11-18 after the sales report was added: `manual_check.py` passed 41 of 41 checks, slowest 88 ms; the report answered in 15 ms in the manager app's live check. Also answers `503` when user-service, book-service, or MySQL is not available, and `404` / `405` for an unknown address or a wrong method.

### POST `/api/orders` — customer

Request: the selected books, each bought or rented.

```json
{
  "items": [
    { "bookId": "655f…a5b6", "type": "BUY" },
    { "bookId": "655f…a5b7", "type": "BUY" },
    { "bookId": "655f…a5b8", "type": "RENT" }
  ]
}
```

Rules: at least one item, at most 50 · `bookId` is a book's id (24 hexadecimal characters) · `type` is `BUY` or `RENT`. The same book with the same type chosen twice becomes one item with `quantity` 2.

What the service does: validates the session → takes the copies of each book from book-service, which answers with its title, author, and price → calculates the charges (buy = price; rent = 10% of price, due in 7 days) → saves the order as `PENDING` in one transaction → writes `bills/bill-<id>.html` → answers → emails the bill to the customer in the background.

If a book does not exist or has too few copies, or the order cannot be saved, the copies already taken are given back and nothing is saved.

Response `201`:

```json
{
  "id": 1042,
  "username": "alice",
  "email": "alice@example.com",
  "createdAt": "2026-11-13T10:05:00",
  "paymentStatus": "PENDING",
  "items": [
    { "title": "Clean Code", "author": "Robert C. Martin", "type": "BUY", "quantity": 1, "unitPrice": 40.00, "rentDueDate": null },
    { "title": "Database System Concepts", "author": "Abraham Silberschatz", "type": "BUY", "quantity": 1, "unitPrice": 55.00, "rentDueDate": null },
    { "title": "Java Concurrency in Practice", "author": "Brian Goetz", "type": "RENT", "quantity": 1, "unitPrice": 8.00, "rentDueDate": "2026-11-20" }
  ],
  "total": 103.00,
  "billFile": "bills/bill-1042.html",
  "billHtml": "<!DOCTYPE html>…",
  "emailQueued": true
}
```

`unitPrice` is what was charged for one copy. `emailQueued` is `true` when the bill has been handed over for emailing and `false` when email is not set up; it does not mean the email has arrived (it is sent after the answer, so that it cannot slow the order down). `billFile` is `null` in the rare case that the file could not be written; the bill is still in `billHtml` and can still be opened with the bill endpoint.

Errors: `400` no items, too many items, a book id in the wrong format, or a type that is not `BUY` or `RENT` (the message names the item) · `401` · `403` not a customer · `404` a book does not exist · `409` a book has no copies available (nothing is saved) · `503` user-service, book-service, or MySQL is not answering (nothing is saved).

### GET `/api/orders` — manager

Response `200`: all orders, newest first.

```json
[
  { "id": 1042, "username": "alice", "createdAt": "2026-11-13T10:05:00", "total": 103.00, "paymentStatus": "PENDING" },
  { "id": 1041, "username": "omar", "createdAt": "2026-11-12T18:40:00", "total": 55.00, "paymentStatus": "PAID" }
]
```

Errors: `401` · `403` not a manager.

### GET `/api/orders/{id}` — owner or manager

Added in M4, so the manager app can show an order's bill in the app (architecture decision 21).

Response `200`: the whole order, in the same shape as the answer to `POST /api/orders` but without `billHtml` and `emailQueued`:

```json
{ "id": 1042, "username": "alice", "email": "alice@example.com", "createdAt": "2026-11-13T10:05:00", "paymentStatus": "PENDING", "items": [ … ], "total": 103.00, "billFile": "bills/bill-1042.html" }
```

Errors: `401` · `403` a customer asking for someone else's order ("This order belongs to another customer") · `404`.

The answer to `POST /api/orders` also carries `email` since M4.

### GET `/api/orders/mine` — customer

Added in M4 for the customer's account page, at the owner's request (architecture decision 23). Not in the PRD.

Response `200`: the customer's own orders, newest first, each a whole order with its items, in the shape of `GET /api/orders/{id}`. An empty list if they have none.

Errors: `401` · `403` a manager ("Only a customer can do this").

### POST `/api/orders/{id}/pay` — the customer who placed it

The pretend checkout, added in M4 at the owner's request (architecture decision 23). Not in the PRD, which leaves payment to the manager (FR13); that endpoint is unchanged. No body: no card details are asked for, sent, or kept. The order is only marked `PAID`, as a manager would mark it.

Response `200`: the whole order, now `"paymentStatus": "PAID"`.

Errors: `401` · `403` a manager ("Only a customer can do this"), or another customer's order ("This order belongs to another customer") · `404` · `409` already paid ("This order is already paid").

### GET `/api/orders/{id}/bill` — owner or manager

Response `200` with `Content-Type: text/html`: the saved bill. If the file is missing, the bill is made again from the saved order (it is identical) and saved again. The bill always says `Pending`: it shows the order as it was placed.

Errors: `401` · `403` a customer asking for someone else's bill · `404` no such order.

### PATCH `/api/orders/{id}/payment-status` — manager

Request:

```json
{ "paymentStatus": "PAID" }
```

Response `200`: the updated order (same shape as one entry of the list). `PENDING` is accepted too, so a manager can undo a mistake.

Errors: `400` a status that is not `PENDING` or `PAID` · `401` · `403` · `404`.

### GET `/api/reports/sales?from=2026-11-01&to=2026-11-30&top=10` — manager

The sales report (extra credit, added in M6, issue #21, course section 6): the orders of a period and what they add up to. The figures are added up in Python from the period's orders, which is fine at a bookstore's scale.

Query, every part optional:

- `from`, `to`: dates as `YYYY-MM-DD`, both included. `to` means up to 23:59:59 of that day. Leaving one out leaves the period open on that side; leaving both out gives every order (all time). `to=9999-12-31` also means no end.
- `top`: how many best sellers to list, 1 to 50; 10 when left out.

A parameter that is present but empty (`?from=`) is an error, not a default: the apps leave out what they do not use.

Response `200`:

```json
{
  "from": "2026-11-01",
  "to": "2026-11-30",
  "orderCount": 3,
  "paidCount": 2,
  "pendingCount": 1,
  "revenue": 198.00,
  "paidRevenue": 95.00,
  "booksSold": 4,
  "booksRented": 1,
  "byDay": [
    { "date": "2026-11-12", "orders": 1, "revenue": 55.00 },
    { "date": "2026-11-13", "orders": 2, "revenue": 143.00 }
  ],
  "bestSellers": [
    { "bookId": "655f…a5b7", "title": "Database System Concepts", "author": "Abraham Silberschatz", "bought": 2, "rented": 0, "copies": 2, "revenue": 110.00 },
    { "bookId": "655f…a5b6", "title": "Clean Code", "author": "Robert C. Martin", "bought": 2, "rented": 0, "copies": 2, "revenue": 80.00 },
    { "bookId": "655f…a5b8", "title": "Java Concurrency in Practice", "author": "Brian Goetz", "bought": 0, "rented": 1, "copies": 1, "revenue": 8.00 }
  ],
  "orders": [
    { "id": 1043, "username": "omar", "createdAt": "2026-11-13T16:20:00", "total": 40.00, "paymentStatus": "PAID" },
    { "id": 1042, "username": "alice", "createdAt": "2026-11-13T10:05:00", "total": 103.00, "paymentStatus": "PENDING" },
    { "id": 1041, "username": "omar", "createdAt": "2026-11-12T18:40:00", "total": 55.00, "paymentStatus": "PAID" }
  ]
}
```

- `from` and `to` are `null` when they were left out.
- `revenue` is the total of every order in the period; `paidRevenue` only of the paid ones. `booksSold` and `booksRented` count copies.
- `byDay` has one entry per day that had orders, oldest first; days without orders are left out.
- `bestSellers` are grouped by `bookId`. Sorted by copies (bought plus rented), then revenue, both highest first, then by title A to Z ignoring upper and lower case. The title and author are those of the book's most recent order.
- `orders` are the period's orders, newest first, in the shape of `GET /api/orders`.
- Money is sent as a JSON number, so `192.50` arrives as `192.5`, the same as the order totals.

Errors, checked in this order:

- `401` no token, or the session has ended.
- `403` a customer: "Only a manager can do this".
- `400` a date that is not `YYYY-MM-DD` or not a real day (`20261118`, `2026-02-30`, or empty): "Enter the dates as YYYY-MM-DD" · `from` after `to`: "The start date must be on or before the end date" · `top` not a whole number from 1 to 50 (`0`, `51`, `-1`, `1.5`, `+5`, or empty): "top must be a whole number from 1 to 50".

---

## Performance (N1)

Every endpoint must answer a typical request in under 500 ms. Measured on the running services, from a cold start: user-service 7–255 ms, book-service 3–38 ms, order-service 6–93 ms. The slowest design risk was `POST /api/orders`, because it calls two other services and sends an email; the email is therefore sent after the response, on a background thread.
