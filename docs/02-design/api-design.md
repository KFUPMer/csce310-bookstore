# Phase 2 — API specification

> Status: **draft**. To be finalized in milestone M2.

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
| 400 | The request is missing a field or a value is invalid |
| 401 | No token, or the token is not valid (not logged in) |
| 403 | Logged in, but this role is not allowed to do this |
| 404 | The book or order does not exist |
| 409 | Conflict: username or email already used, or no copies available |

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
| order | POST | `/api/orders` | Customer | FR6–FR10 |
| order | GET | `/api/orders` | Manager | FR12 |
| order | GET | `/api/orders/{id}/bill` | Owner or Manager | FR8, FR9 |
| order | PATCH | `/api/orders/{id}/payment-status` | Manager | FR13 |

---

## user-service — `http://localhost:8081`

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

Rules: username 3–50 characters · email must look like an email · password at least 8 characters. The password is hashed with bcrypt (N3). The new account always has role `CUSTOMER`.

Response `201`:

```json
{ "userId": 3, "username": "alice", "email": "alice@example.com", "role": "CUSTOMER" }
```

Errors: `400` a field is missing or invalid · `409` username or email already used.

---

## book-service — `http://localhost:8082`

A book looks like this everywhere:

```json
{ "id": "655f1c2ab7e4a1d2c3f4a5b6", "title": "Clean Code", "author": "Robert C. Martin", "price": 40.00, "copiesAvailable": 4, "coverUrl": null }
```

`coverUrl` is optional (the address of a cover image, or `null`). It can be set in POST and PUT.

### GET `/api/books?keyword=java`

Returns the books whose **title or author** contains the keyword, ignoring upper and lower case. Without a keyword, returns all books. Sorted by title.

Response `200`:

```json
[
  { "id": "…", "title": "Effective Java", "author": "Joshua Bloch", "price": 50.00, "copiesAvailable": 4 },
  { "id": "…", "title": "Head First Java", "author": "Kathy Sierra and Bert Bates", "price": 35.00, "copiesAvailable": 7 }
]
```

An empty list `[]` when nothing matches. Errors: `401`.

### GET `/api/books/{id}`

Response `200`: one book. Errors: `401` · `404`.

### POST `/api/books` — manager

Request:

```json
{ "title": "Clean Architecture", "author": "Robert C. Martin", "price": 42.00, "copiesAvailable": 3 }
```

Rules: title and author not empty · price greater than 0 · copies 0 or more.

Response `201`: the new book, with its `id`. Errors: `400` · `401` · `403` not a manager.

### PUT `/api/books/{id}` — manager

Request: the same four fields as POST. Response `200`: the updated book.

Errors: `400` · `401` · `403` · `404`.

### PATCH `/api/books/{id}/copies` — order-service only

Used when an order is placed. Not for the apps: it needs the header `X-Service-Key`, a secret shared by the services through configuration.

Request:

```json
{ "change": -1 }
```

Response `200`: the updated book. Errors: `403` wrong or missing service key · `404` · `409` not enough copies.

---

## order-service — `http://localhost:8083`

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

What the service does: validates the session → gets each book from book-service → calculates the charges (buy = price; rent = 10% of price, due in 7 days) → saves the order as `PENDING` → reduces each book's copies by one → writes `bills/bill-<id>.html` → emails the bill to the customer.

Response `201`:

```json
{
  "id": 1042,
  "username": "alice",
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
  "emailSent": true
}
```

Errors: `400` no items, or a type that is not `BUY` or `RENT` · `401` · `403` not a customer · `404` a book does not exist · `409` a book has no copies available (nothing is saved).

### GET `/api/orders` — manager

Response `200`: all orders, newest first.

```json
[
  { "id": 1042, "username": "alice", "createdAt": "2026-11-13T10:05:00", "total": 103.00, "paymentStatus": "PENDING" },
  { "id": 1041, "username": "omar", "createdAt": "2026-11-12T18:40:00", "total": 55.00, "paymentStatus": "PAID" }
]
```

Errors: `401` · `403` not a manager.

### GET `/api/orders/{id}/bill` — owner or manager

Response `200` with `Content-Type: text/html`: the saved bill.

Errors: `401` · `403` a customer asking for someone else's bill · `404`.

### PATCH `/api/orders/{id}/payment-status` — manager

Request:

```json
{ "paymentStatus": "PAID" }
```

Response `200`: the updated order (same shape as one entry of the list).

Errors: `400` a status that is not `PENDING` or `PAID` · `401` · `403` · `404`.

---

## Performance (N1)

Every endpoint must answer a typical request in under 500 ms. The slowest is `POST /api/orders`, because it calls two other services and sends an email. If the email makes it too slow, it will be sent after the response instead of before it.
