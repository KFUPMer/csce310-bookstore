# book-service

Search books, and add and update them. Customers' reviews and star ratings of books. Python, Flask, MongoDB.

Requirements covered: FR4, FR5, FR6, FR14, N1, N4, N5, and the extra-credit book reviews and ratings (course section 6, issue #20).

## Endpoints

| Method | Path | Who | Does |
|---|---|---|---|
| GET | `/api/books?keyword=&category=` | Logged in | Books whose title or author contains the keyword; all books without one. `category` keeps one shelf (Fiction, Nonfiction, Kids, Science, Technology; added in M5) |
| GET | `/api/books/{id}` | Logged in | One book |
| POST | `/api/books` | Manager | Adds a book |
| PUT | `/api/books/{id}` | Manager | Updates a book |
| PATCH | `/api/books/{id}/copies` | order-service only | Takes or returns copies |
| GET | `/api/books/{id}/reviews` | Logged in | The book's reviews, most recently written or changed first (added in M6) |
| PUT | `/api/books/{id}/reviews/mine` | Customer | Writes the customer's review (1 to 5 stars, optional text), or replaces the one they wrote before (added in M6) |
| DELETE | `/api/books/{id}/reviews/mine` | Customer | Deletes the customer's own review; answers 204 (added in M6) |

Every book in every answer also carries `ratingAverage` and `ratingCount`, worked out from the reviews.

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

71 tests:

| File | Tests | What |
|---|---|---|
| `test_api.py` | 29 | Every book endpoint, success and each error, with in-memory repositories and a stand-in for user-service |
| `test_reviews_api.py` | 25 | The three review endpoints and the ratings on books, the same way |
| `test_mongo_repository.py` | 17 | The book repository (9) and the review repository (8) against a real MongoDB; skipped if MongoDB is not running |

The first two files need nothing running. The MongoDB tests use a separate `bookstore_test` database that is dropped afterwards.

## How it is built

Four layers; each only calls the one below ([engineering rules](../../docs/02-design/engineering-rules.md)):

| File | Layer | Holds |
|---|---|---|
| `routes.py` | Receives requests, checks who is asking, returns JSON | The eight endpoints |
| `schemas.py` | The shape of a request, with its validation | `BookInput`, `CopiesChange`, `ReviewInput` |
| `services.py` | The rules | `BookService` (now also fills in each book's rating), `ReviewService`, `average_rating()` |
| `repository.py` | Database access | `BookRepository` and `ReviewRepository`, each with a MongoDB and an in-memory version |
| `models.py` | Plain data | `Book`, `Review`, `RatingTotals`, `CurrentUser` |

Plus `auth.py` (asks user-service who a token belongs to), `errors.py` (the errors, and the one place that answers them), `config.py` (settings), `app.py` (puts the parts together), and `__main__.py` (start-up).

Class diagram and a description of every file: [class-diagrams.md](../../docs/02-design/class-diagrams.md#book-service).

## Error handling

Routes and services raise; `errors.py` answers every failure as `{ "error": "message" }`:

| Raised | Answer |
|---|---|
| `ValidationError` | 400, with a message naming the field |
| `UnauthorizedError` | 401: no token, or the session has ended |
| `ForbiddenError` | 403: a customer on a manager endpoint, a manager writing a review, or no service key |
| `NotFoundError` | 404: no such book, or no review of yours to delete |
| `ConflictError` | 409: not enough copies |
| `ServiceUnavailableError` | 503: user-service or MongoDB is not answering |
| Body is not JSON, unknown address, wrong method | 400, 404, 405 |
| Anything else | 500 with a general message; details go to the log only |

## Things worth knowing

- **Search is safe against odd input.** The keyword is matched as plain text, so typing `(` or `.*` or `c++` cannot break or change the search.
- **The last copy cannot be sold twice.** Taking copies is one atomic database step. A test fires 20 attempts at once at a book with one copy; exactly one succeeds.
- **If user-service is down**, this service answers 503 within about two seconds, rather than hanging or pretending the user is logged out.
- **The copies endpoint is closed to the apps.** It needs a key shared only by the services; a manager's token is not enough.
- **One review per customer per book.** The `reviews` collection has a unique index, `one_review_per_customer_per_book`, on (`bookId`, `userId`). It is made at start-up, or before the first save if MongoDB was down then. A review is stored under the book's own lowercase id: MongoDB accepts an id in capital letters too, and a review sent that way was once stored under a second spelling (found in review, fixed, with a test).
- **Any customer may review any book**, not only one they bought. Checking purchases would make this service call order-service, which already calls this one.

## Status

Built and verified on 2026-11-16:

- All 31 tests pass. After shelves were added (M5): all 37 pass, and the apps' live checks found the Fiction shelf on the running service in 25 ms.
- Run for real with user-service, MySQL, and MongoDB: all 16 checks (every endpoint, success and errors) returned the expected result.
- Timings on the running service: 3 to 38 ms per request, including the session check with user-service. N1 allows 500 ms.

Reviews and ratings, added 2026-11-18 (issue #20):

- All 71 tests pass, with MongoDB running, so none was skipped.
- After restarting the services on the new code, the customer app's live check saved a review in 15 ms; it was listed first, and the book's `ratingCount` went up by one. The review was then deleted. Login took 158 ms, a search 14 ms. `manual_check.py` passed 41 of 41 checks, slowest 88 ms.
- Afterwards the real `reviews` collection was empty, with the unique index present.
- **Not verified:** `manual_check.py` does not call the review endpoints; on the running service they were checked only through the customer app's live check. Ratings with many reviews were tested only with the in-memory and test-database repositories.
