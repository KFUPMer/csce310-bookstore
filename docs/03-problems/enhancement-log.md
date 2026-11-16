# Enhancement log

Improvements made **beyond what the requirements or the first design asked for**: what was added, why, and what it changed. Problems and their fixes are in the [problem log](problem-log.md); a fix that also left the project better than planned appears in both.

Each entry says whether the PRD required it. "No" means it was a choice, and could be removed without failing a requirement.

## Summary

| ID | Date | Enhancement | Area | Required by PRD? |
|---|---|---|---|---|
| E-001 | 2026-11-13 | Every design traces to a requirement | Docs | No |
| E-002 | 2026-11-13 | Placing an order reduces the available copies | Design | Implied |
| E-003 | 2026-11-13 | Books can have a cover image; a cover is generated when there is none | Apps, database | No |
| E-004 | 2026-11-13 | Cover grid with a list view, instead of only a table | Customer app | No (FR5 needs a clear list) |
| E-005 | 2026-11-13 | Search filters as you type | Customer app | No |
| E-006 | 2026-11-13 | Undo after adding a book; Esc and Ctrl+F shortcuts | Customer app | No |
| E-007 | 2026-11-13 | Light and dark mode | Both apps | No |
| E-008 | 2026-11-13 | Color-blind-safe states and checked contrast | Both apps | No |
| E-009 | 2026-11-13 | One shared UI package for both apps | Apps | No |
| E-010 | 2026-11-13 | Smooth mouse-wheel scrolling | Both apps | No |
| E-011 | 2026-11-13 | Typefaces bundled with the apps | Both apps | No |
| E-012 | 2026-11-13 | Memory mode: a service can run without its database | user-service | No |
| E-013 | 2026-11-13 | Login does not reveal which usernames exist | user-service | No |
| E-014 | 2026-11-13 | Services listen on both loopback addresses | user-service | No (helps N1) |
| E-015 | 2026-11-13 | Database connection pool | user-service | No (helps N1) |
| E-016 | 2026-11-13 | Start-up warm-up | user-service | No (helps N1) |
| E-017 | 2026-11-13 | A dedicated, limited MySQL account instead of root | Database | No |
| E-018 | 2026-11-13 | Request validation with messages that name the field | user-service | Partly (FR3 asks for a valid email) |
| E-019 | 2026-11-13 | Tests that call the real server over HTTP | user-service | No |
| E-020 | 2026-11-13 | Generated diagrams, checked after every export | Docs | No |
| E-021 | 2026-11-16 | The last copy of a book cannot be sold twice | book-service | No |
| E-022 | 2026-11-16 | A clear answer when another service is down | book-service | No |
| E-023 | 2026-11-16 | Search treats the keyword as plain text | book-service | No |
| E-024 | 2026-11-16 | Database tests on a separate, disposable database | book-service | No |

## Details

### E-001 — Every design traces to a requirement

Each service, table, endpoint, class, screen, and use case in the design documents names the requirement (FR or N number) it exists for.
**Why:** it shows nothing was built without a reason and nothing required was forgotten.
**Effect:** this is how the features the PRD does not ask for (reviews, order history) were found and removed.

### E-002 — Placing an order reduces the available copies

The PRD says the manager can update the number of copies, but not that ordering changes it. The order service now reduces each ordered book's copies, through an endpoint only it can call.
**Why:** without it, a book with one copy could be sold any number of times, and "available copies" would mean nothing.
**Where:** [api-design.md](../02-design/api-design.md) (`PATCH /api/books/{id}/copies`), architecture decision 5.

### E-003 — Cover images, with a generated fallback

A book has an optional `coverUrl`. With none, the app draws a cover from the title: a muted color that is always the same for that title, the title in a serif, and a sheen.
**Why:** the approved style makes book covers the only color in the interface, and the sample books have no images.
**Where:** `clients/bookstore-ui/lib/src/book_cover.dart`, [style-guide.md](../02-design/style-guide.md).

### E-004 — Cover grid with a list view

The wireframe showed search results as a table. The app shows a grid of covers and offers the table as a list view.
**Why:** browsing by cover is how people look for books; the list is faster for scanning prices. FR5 is met by both.

### E-005 — Search as you type

Results update with each keystroke instead of after pressing a Search button.
**Why:** fewer steps, and the heading always says how many books match (Nielsen 1: visibility of system status).

### E-006 — Undo and keyboard shortcuts

Adding a book shows a message with Undo. Esc closes the detail panel, then clears the search. Ctrl+F jumps to the search field.
**Why:** Nielsen 3 (user control and freedom) and 7 (efficiency of use).

### E-007 — Light and dark mode

Two palettes with the same structure; one button switches, with an animated transition.
**Why:** asked for by the project owner. Costs little because every color comes from one file.

### E-008 — Color-blind-safe states and checked contrast

No state is shown by color alone: availability, errors, and payment status always have an icon and a word. Every text color was measured against WCAG AA (4.5:1) in both modes.
**Why:** asked for by the project owner.
**Effect:** one color failed the first measurement (light-mode tertiary text, 4.05) and was darkened to 4.7 before it was ever used.

### E-009 — One shared UI package

Colors, type, spacing, motion, and the common widgets live in `clients/bookstore-ui`, used by both apps.
**Why:** two apps that must look identical should not each hold a copy of the look. A color changes in one place.

### E-010 — Smooth mouse-wheel scrolling

Flutter on desktop moves a page in steps per wheel notch. The apps animate to the new position instead.
**Why:** "as smooth as possible" was the brief.
**Not yet verified:** how it feels has to be judged by hand; a screenshot cannot show it.

### E-011 — Bundled typefaces

Inter and Source Serif 4 are shipped inside the app, with their licenses.
**Why:** the app looks the same on every machine, including the one it is demonstrated on. (Apple's SF Pro could not be used; see P-010.)

### E-012 — Memory mode

`STORAGE=memory` runs user-service with no database, using the two test accounts.
**Why:** the service could be built and tested before the MySQL database existed, and the apps can be developed without MySQL running.
**How:** the rules depend on repository interfaces; there is a MySQL version and an in-memory version of each.
**Effect:** all 26 tests run in about 3 seconds with no database.

### E-013 — Login does not reveal which usernames exist

A wrong password and an unknown username get the same message, and the service does the same amount of work for both, so the response time is the same too.
**Why:** otherwise someone could find valid usernames by trying names and watching the answers. Not required, but standard practice and nearly free.

### E-014 — Both loopback addresses

The service listens on `127.0.0.1` and `::1`.
**Why and effect:** see P-004. The first request by the name `localhost` went from about 2,100 ms to about 135 ms.

### E-015 — Database connection pool

Connections are borrowed from a pool (HikariCP) instead of opened per query.
**Why and effect:** see P-005. A session check went from about 75 ms to 7–19 ms. That call is made by the other two services on every request, so it speeds up the whole system.

### E-016 — Start-up warm-up

At start-up the service practises password hashing and sends itself one refused login.
**Why and effect:** see P-005. The first login after a cold start went from 509–539 ms to 102–255 ms.

### E-017 — A dedicated, limited MySQL account

The services log in as `bookstore_app`, which can only read and write the bookstore database. Its password is generated on the machine and kept out of git. The root password is typed once by its owner and never stored.
**Why:** least privilege. If the app's password leaked, only bookstore data would be exposed. It also meant the root password never had to be shared.
**Verified:** the account was confirmed unable to read another database.

### E-018 — Validation that names the field

A bad request is answered with what is wrong and where: "The password must be at least 8 characters long", not "Bad request".
**Why:** the app can show the message next to the field as it is (Nielsen 9: help users recover from errors).

### E-019 — Tests over real HTTP

Eleven of the 26 tests start the real server on a free port and call each endpoint the way the apps will, for success and for every error.
**Why:** unit tests alone would not catch a wrong status code, a missing header, or a route that is not registered.
**Limit found:** these tests still missed P-004 and P-005, which only showed when the packaged service was run by hand. See those entries.

### E-020 — Generated, checked diagrams

The draw.io files are produced by scripts, and every exported image is looked at before it is committed.
**Why:** diagrams stay consistent with each other and can be regenerated when the design changes.
**Effect:** about a dozen layout faults were caught this way before being committed (see P-011).
**Where:** the scripts are in `tools/diagrams`, with a README. One of them still has a known fault; see "Known gaps" in the problem log.

### E-021 — The last copy cannot be sold twice

Taking copies is done in one atomic MongoDB step: "reduce the copies, but only if enough remain". It is not "read the number, check it, write it back".
**Why:** with read-then-write, two orders arriving at the same moment could both read "1 copy" and both succeed.
**Verified:** a test fires 20 attempts at once at a book with one copy. Exactly one succeeds, and the book ends at 0, not below.

### E-022 — A clear answer when another service is down

book-service asks user-service who each token belongs to. If user-service does not answer within about two seconds, book-service replies `503` with "The login service is not answering. Please try again in a moment."
**Why:** the alternatives are a frozen app, or wrongly telling a logged-in user they are logged out. The same is done if MongoDB is down.
**Verified:** user-service was stopped while book-service ran; the search answered 503 in 2.0 seconds.

### E-023 — Search treats the keyword as plain text

The keyword is escaped before it is used in the database's pattern search.
**Why:** otherwise typing `(` would cause an error, and `.*` would match every book. It also closes a way to make the database do expensive work on purpose.
**Verified:** tests search for `(`, `[`, `.*`, `\`, and `c++`; the last finds "The C++ Programming Language".

### E-024 — Database tests on a disposable database

The tests of the MongoDB repository run against a real MongoDB, but in a database of their own (`bookstore_test`) that is emptied before each test and dropped at the end.
**Why:** testing against the real thing catches what a stand-in cannot, and the real `bookstore` data is never touched.
