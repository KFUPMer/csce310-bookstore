# Phase 2 — API design

> Status: **proposed starting point**. To be finalized in milestone M2.

All services exchange JSON. Errors use a common shape: `{ "error": "message" }` with the matching HTTP status code.

## user-service (`:8081`)

| Method | Path | Description |
|---|---|---|
| POST | `/api/users/register` | Create an account |
| POST | `/api/users/login` | Log in |
| GET | `/api/users/{id}` | Get a user profile |

## catalog-service (`:8082`)

| Method | Path | Description |
|---|---|---|
| GET | `/api/books` | List/search books (`?q=`, `?category=`) |
| GET | `/api/books/{id}` | Book details |
| POST | `/api/books` | Add a book (staff) |
| PUT | `/api/books/{id}` | Edit a book (staff) |
| DELETE | `/api/books/{id}` | Remove a book (staff) |
| PATCH | `/api/books/{id}/stock` | Update stock (staff) |
| POST | `/api/books/{id}/reviews` | Add a review |

## order-service (`:8083`)

| Method | Path | Description |
|---|---|---|
| POST | `/api/orders` | Place an order |
| GET | `/api/orders/{id}` | Order details |
| GET | `/api/orders?userId=` | A customer's order history |
| GET | `/api/orders` | All orders (staff) |
| PATCH | `/api/orders/{id}/status` | Update order status (staff) |

## Still to do in M2

- [ ] Request and response body for every endpoint
- [ ] Status codes per endpoint
- [ ] Decide how staff-only endpoints are protected
