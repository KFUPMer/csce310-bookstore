# Phase 2 — API design

> Status: **draft**, based on the official PRD. To be finalized in milestone M2.

All services exchange JSON. Errors use one shape: `{ "error": "message" }` with the matching HTTP status code.

Every endpoint except login and register needs the session token in the `Authorization` header.

## user-service (`:8081`)

| Method | Path | Who | Description | Requirement |
|---|---|---|---|---|
| POST | `/api/auth/login` | Anyone | Log in with username and password; returns a session token and the role | FR1 |
| POST | `/api/auth/logout` | Logged in | End the session | FR2 |
| GET | `/api/auth/session` | Services | Check a token; returns the user and role | FR2, FR11 |
| POST | `/api/users/register` | Anyone | Create an account (username, password, email) | FR3 (optional) |

## catalog-service (`:8082`)

| Method | Path | Who | Description | Requirement |
|---|---|---|---|---|
| GET | `/api/books?keyword=` | Logged in | Search by keyword in title and author; returns title, author, price | FR4, FR5 |
| GET | `/api/books/{id}` | Logged in | One book | FR6 |
| POST | `/api/books` | Manager | Add a new book | FR14 |
| PUT | `/api/books/{id}` | Manager | Update a book (e.g. available copies) | FR14 |

## order-service (`:8083`)

| Method | Path | Who | Description | Requirement |
|---|---|---|---|---|
| POST | `/api/orders` | Customer | Create an order from the selected books (each `BUY` or `RENT`); generates and saves the HTML bill | FR6–FR9 |
| GET | `/api/orders/{id}/bill` | Owner or manager | The bill as HTML | FR8, FR9 |
| GET | `/api/orders` | Manager | List all orders | FR12 |
| PATCH | `/api/orders/{id}/payment-status` | Manager | Change payment status, e.g. `PENDING` → `PAID` | FR13 |

A rented book is charged at 10% of its price and is due back 7 days after the order; order-service calculates both.

FR10 (optional) adds no endpoint: order-service emails the bill when the order is created.

## Still to do in M2

- [ ] Request and response body for every endpoint
- [ ] Status codes per endpoint
