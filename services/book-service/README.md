# book-service

Search books, and add and update them. Python, Flask, MongoDB.

Requirements covered: FR4, FR5, FR6, FR14, N1, N4, N5.

## Endpoints

| Method | Path | Who | Does |
|---|---|---|---|
| GET | `/api/books?keyword=` | Logged in | Books whose title or author contains the keyword; all books without one |
| GET | `/api/books/{id}` | Logged in | One book |
| POST | `/api/books` | Manager | Adds a book |
| PUT | `/api/books/{id}` | Manager | Updates a book |
| PATCH | `/api/books/{id}/copies` | order-service only | Takes or returns copies |

Exact requests, responses, and errors: [api-design.md](../../docs/02-design/api-design.md).

## Run

Needs MongoDB and user-service running, and `services/.env` (see [environment.md](../../docs/05-setup/environment.md)).

```bash
pip install -r requirements.txt
```

```bash
python -m book_service
```

Listens on port 8082 (change with `BOOK_SERVICE_PORT`), on this machine only.

## Test

```bash
python -m unittest discover -s tests -t .
```

31 tests. 24 call every endpoint with an in-memory repository and a stand-in for user-service, so they need nothing running. 7 test the MongoDB repository against a real MongoDB, in a separate `bookstore_test` database that is dropped afterwards; they are skipped if MongoDB is not running.

## How it is built

Four layers; each only calls the one below ([engineering rules](../../docs/02-design/engineering-rules.md)):

| File | Layer | Holds |
|---|---|---|
| `routes.py` | Receives requests, checks who is asking, returns JSON | The five endpoints |
| `schemas.py` | The shape of a request, with its validation | `BookInput`, `CopiesChange` |
| `services.py` | The rules | `BookService` |
| `repository.py` | Database access | `BookRepository`, with a MongoDB and an in-memory version |
| `models.py` | Plain data | `Book`, `CurrentUser` |

Plus `auth.py` (asks user-service who a token belongs to), `errors.py` (the errors, and the one place that answers them), `config.py` (settings), `app.py` (puts the parts together), and `__main__.py` (start-up).

Class diagram and a description of every file: [class-diagrams.md](../../docs/02-design/class-diagrams.md#book-service).

## Error handling

Routes and services raise; `errors.py` answers every failure as `{ "error": "message" }`:

| Raised | Answer |
|---|---|
| `ValidationError` | 400, with a message naming the field |
| `UnauthorizedError` | 401: no token, or the session has ended |
| `ForbiddenError` | 403: a customer on a manager endpoint, or no service key |
| `NotFoundError` | 404 |
| `ConflictError` | 409: not enough copies |
| `ServiceUnavailableError` | 503: user-service or MongoDB is not answering |
| Body is not JSON, unknown address, wrong method | 400, 404, 405 |
| Anything else | 500 with a general message; details go to the log only |

## Things worth knowing

- **Search is safe against odd input.** The keyword is matched as plain text, so typing `(` or `.*` or `c++` cannot break or change the search.
- **The last copy cannot be sold twice.** Taking copies is one atomic database step. A test fires 20 attempts at once at a book with one copy; exactly one succeeds.
- **If user-service is down**, this service answers 503 within about two seconds, rather than hanging or pretending the user is logged out.
- **The copies endpoint is closed to the apps.** It needs a key shared only by the services; a manager's token is not enough.

## Status

Built and verified on 2026-11-16:

- All 31 tests pass.
- Run for real with user-service, MySQL, and MongoDB: all 16 checks (every endpoint, success and errors) returned the expected result.
- Timings on the running service: 3 to 38 ms per request, including the session check with user-service. N1 allows 500 ms.
