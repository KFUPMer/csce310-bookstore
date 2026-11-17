# order-service

Places orders, makes and saves the HTML bill, emails it, lists orders, and updates the payment status. Python, Flask, MySQL.

Requirements covered: FR6, FR7, FR8, FR9, FR10 (extra credit), FR12, FR13, N1, N4, N5.

## Endpoints

| Method | Path | Who | Does |
|---|---|---|---|
| POST | `/api/orders` | Customer | Places an order for the selected books, each bought or rented; answers with the order and its bill |
| GET | `/api/orders` | Manager | All orders, newest first |
| GET | `/api/orders/mine` | Customer | The customer's own orders with their items, newest first (added in M4 for the account page) |
| GET | `/api/orders/{id}` | The customer who placed it, or a manager | One order with its items, as JSON (added in M4 for the manager app) |
| POST | `/api/orders/{id}/pay` | The customer who placed it | The pretend checkout: marks the order paid. No card details; beyond the PRD (added in M4) |
| GET | `/api/orders/{id}/bill` | The customer who placed it, or a manager | The bill, as HTML |
| PATCH | `/api/orders/{id}/payment-status` | Manager | Sets `PENDING` or `PAID` |

Exact requests, responses, and errors: [api-design.md](../../docs/02-design/api-design.md).

## Run

Needs MySQL, user-service, and book-service running, and `services/.env` (see [environment.md](../../docs/05-setup/environment.md)).

```bash
pip install -r requirements.txt
```

```bash
python -m order_service
```

Listens on port 8083 (change with `ORDER_SERVICE_PORT`), on this machine only. Bills are saved in `services/order-service/bills/` (change with `BILLS_FOLDER`); the folder is ignored by git.

Email: bills are emailed only when `SMTP_USER` and `SMTP_PASSWORD` are filled in in `services/.env`. Without them the service says so at start-up and everything else works.

## Test

```bash
python -m unittest discover -s tests -t .
```

101 tests:

| File | Tests | What |
|---|---|---|
| `test_api.py` | 49 | Every endpoint, success and each error, with stand-ins for the other services |
| `test_rules.py` | 17 | The renting price, request validation, settings |
| `test_bill.py` | 14 | What is on the bill, and saving it |
| `test_book_catalog.py` | 7 | The client for book-service, against a small real web server that answers like it |
| `test_mailer.py` | 5 | The email message, and that a failed send is logged and never raised |
| `test_mysql_repository.py` | 9 | The repository against the real MySQL; skipped if MySQL is not reachable |

The MySQL tests run in the real `bookstore` database, because the services' account is not allowed to create another one. They only touch the orders of their own temporary user (`order_repo_test`) and delete that user afterwards. One side effect: each run uses up a few order numbers, so real order ids do not stay consecutive.

## Check the running service

```bash
python manual_check.py
```

Starts all three services, calls every endpoint for real (41 checks, each stating what it expects), times each call from a cold start, cleans up what it created, stops the services, and confirms none is left running.

```bash
python email_check.py
```

Sends one real bill email: places one order as a temporary customer whose email is the sending address itself, waits for the log to say whether Gmail accepted it, and cleans up. Needs `SMTP_USER` and `SMTP_PASSWORD` in `services/.env`.

## How it is built

Four layers; each only calls the one below ([engineering rules](../../docs/02-design/engineering-rules.md)):

| File | Layer | Holds |
|---|---|---|
| `routes.py` | Receives requests, checks who is asking, returns the answer | The seven endpoints |
| `schemas.py` | The shape of a request, with its validation | `OrderInput`, `OrderLine`, `PaymentStatusInput` |
| `services.py` | The rules | `OrderService`, `PlacedOrder` |
| `pricing.py` | The renting rule, in one place | `RENT_RATE`, `RENT_DAYS`, `charge_for()` |
| `bill.py` | The bill | `render_bill()`, `BillStore` |
| `catalog.py` | Books, through book-service | `BookCatalog`, `BookServiceCatalog` |
| `mailer.py` | Email | `Mailer`, `SmtpMailer`, `NoMailer` |
| `repository.py` | Database access | `OrderRepository`, with a MySQL and an in-memory version |
| `models.py` | Plain data | `Order`, `OrderItem`, `CurrentUser`, `CatalogBook` |

Plus `auth.py` (asks user-service who a token belongs to), `errors.py` (the errors, and the one place that answers them), `config.py` (settings), `app.py` (puts the parts together), and `__main__.py` (start-up).

`errors.py` and the session check in `auth.py` are the same as book-service's on purpose: each service is its own project and can run alone, so they do not share code.

Class diagram and a description of every file: [class-diagrams.md](../../docs/02-design/class-diagrams.md#order-service).

## How an order is placed

1. Check the session with user-service; only a customer may order.
2. Check the request: at least one book, at most 50, each `BUY` or `RENT`. The same book chosen twice becomes one line with quantity 2.
3. Take the copies from book-service, one call per book. That call is atomic and answers with the book's title, author, and price.
4. Work out the charges: buy = the price; rent = 10% of the price, due back in 7 days.
5. Save the order and its items in MySQL, in one transaction, as `PENDING`.
6. Write `bills/bill-<id>.html` and record its name with the order.
7. Answer `201` with the order and the bill. The email is sent afterwards, in the background.

**All or nothing.** If a book does not exist (404) or has too few copies (409), or the order cannot be saved, every copy already taken is given back and nothing is saved.

**After the order is saved it stands.** If the bill file cannot be written, or the email fails, the problem is logged and the order still succeeds. A missing bill file is made again, identical, the next time the bill is opened: a bill depends only on the saved order.

## Error handling

Routes and services raise; `errors.py` answers every failure as `{ "error": "message" }`:

| Raised | Answer |
|---|---|
| `ValidationError` | 400, with a message naming the item |
| `UnauthorizedError` | 401: no token, or the session has ended |
| `ForbiddenError` | 403: wrong role, or someone else's bill |
| `NotFoundError` | 404: no such order or book |
| `ConflictError` | 409: a book has no copies available |
| `ServiceUnavailableError` | 503: user-service, book-service, or MySQL is not answering |
| Body is not JSON, unknown address, wrong method | 400, 404, 405 |
| Anything else | 500 with a general message; details go to the log only |

## Things worth knowing

- **Money is exact.** Prices are `Decimal`, never `float`, and a rent charge is rounded to the cent, half up.
- **Nothing typed by a user can become HTML or SQL.** Titles, authors, and names are escaped on the bill; every database value is passed as a parameter; a book id must be 24 hexadecimal characters before it is used in an address.
- **Secrets stay out of the log.** Printing the settings never shows a password or the service key, and a failed email is logged without them.
- **Email never slows an order.** It is sent on a background thread, so `emailQueued: true` means "being sent", not "delivered".

## Status

Built and verified on 2026-11-16:

- All 101 tests pass, including the 9 against the real MySQL (re-run 2026-11-17 after the M4 endpoints).
- Run for real with user-service, book-service, MySQL, and MongoDB: all 33 checks returned the expected result, and no service was left running. Run again on 2026-11-17 with the three M4 endpoints added: all 41 checks passed, slowest request 147 ms.
- Timings on the running service: the first order after a cold start took 93 ms; every other request took 6 to 44 ms. N1 allows 500 ms.
- With book-service stopped, placing an order answered 503 in 2.0 seconds and order-service kept running.

- A real bill was sent through Gmail with `python email_check.py`: the order answered in 101 ms and Gmail accepted the email afterwards ("Emailed the bill for order 1033" in the log). That first email showed the layout broken in Gmail; it was fixed (problem P-016) and a second one sent.

The owner opened the second email in Gmail and it looks as designed.

**Not verified:** how the bill looks in other mail programs (Outlook, phone apps).

**Payment:** the PRD says there is no real-time payment processing: a manager marks the order as paid by hand (FR13), and that still works. At the owner's request, the customer app also has a pretend checkout (`POST /api/orders/{id}/pay`) that marks the customer's own order paid. It handles no money and no card details. The emailed bill has no Pay button.

Known limits are listed under "Known gaps" in the [problem log](../../docs/03-problems/problem-log.md).
