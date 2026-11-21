# Changelog

All versions and patches of the project, newest first.

## Unreleased

- The front page (README.md) redone for anyone passing by: a picture of both apps at the top, a gallery of eight screenshots, how to try it, how it is built, and the project in numbers.
- HANDOVER.md, for the instructor, tidied: an "at a glance" table, the accounts in one table, screenshots of key steps, and up-to-date counts.
- The architecture diagram now shows the apps' names, reviews, the sales report, and the emailed bill.
- The customer app's screenshots now use one consistent set of orders (the bill, the account page, and the pay dialog all show order 1045).
- `manual_check.py` prints the end of a service's log when that service does not start (P-018).
- The course report (`docs/07-report`): database design, the REST API with its JSON, every major screen, and the architecture and classes (client/server, three tiers, MVC), built to PDF by `tools/report/build_report.py`. Also the recording script for the acceptance-test videos, covering FR1 to FR14.
- Six faults found by a repository audit, fixed (P-023): a test-data reset no longer leaves every rating pointing at deleted books; a manager's book edit can no longer undo an order placed while the form was open (`copiesBefore`, 409); book-service answers 503, not 500, when something else answers on user-service's port; the report build stops on a missing section or a link without `https://`; emails are lower-cased the same way on every computer. 340 tests.
- A second audit (P-024): `stop-services` stops only its own java and python processes, never another program that has reused an id after a restart; a slow order now tells the customer to check Your account before ordering again. Unused diagram-script code removed (about 110 lines). 341 tests.
- The apps start the services themselves (E-052): when Mooney's or Mooney's Manager opens and the services are not running, it starts them in the background and says so on the login screen (11 s here). No more start-services.cmd step. 346 tests.
- The course report, after the owner read it: one clear table per database entity (column, type, key, meaning); the use-case, component, state-machine, and four sequence diagrams added; a "Sources" line under each section; "6. Accounts for testing" and "7. References"; the course and instructor on the cover and in every page footer. The student's details come from a git-ignored file. The state machine now shows that the customer can also pay.
- The course report rewritten short, as proof rather than reference (75 pages to 25): the entities, attributes and relationships with the ER diagram; all 20 endpoints with their input and output, and real JSON for the main flows; the screens two to a page; the patterns, the main classes, and the class diagrams. One video instead of four.
- The ER diagram redrawn with the `reviews` collection and every current field and type; `database-design.md` and `api-design.md` brought up to date with the code and marked final (P-021).

## v1.2.0 — 2026-11-18 — A full shop: 81 books and demo sales

A lived-in shop from the first start: 54 more books on the shelves, and demo customers with past sales and reviews, so the Reports tab, the best sellers, and the star ratings show real figures straight away. Asked for by the owner. Nothing in the API or the apps' behaviour changed; all tests pass. Install: [INSTALL.md](INSTALL.md).

| File | What it is |
|---|---|
| `Mooneys-Apps-Setup-1.2.0.exe` | Installs both apps for the current user (no administrator needed) |
| `Mooneys-Apps-1.2.0-portable.zip` | The same two apps, to unzip and run |
| `Mooneys-Server-1.2.0.zip` | The services and the whole source; `setup.cmd` now also loads the 81 books and the demo data |

Demo customers log in with the password `demo12345` (for example `omar.aziz`). The test accounts are unchanged: `customer1` / `customer123`, `manager1` / `manager123`.

### Added
- 54 more books (81 in all), each with a checked Open Library cover: Fiction 16, Nonfiction 14, Kids 14, Science 14, Technology 23
- `database/demo_data.py`: 14 invented customers with random names, 100 past sales at random dates over the last 60 days, and 96 reviews by customers of books they ordered; run by setup.cmd, removable with `--remove`

## v1.1.0 — 2026-11-18 — Extra credit: reviews, ratings, and sales reports

The three extra-credit items of the course document's section 6 (milestone M6, issues #19, #20, #21). User profiles with order history were already built in v0.4.0 as the customer's "Your account" page; this version adds book reviews and ratings, and a sales report for managers. A minor version: new features, nothing removed or changed in the existing API. All 333 tests pass, and the 41 checks of `manual_check.py` pass on the running services (slowest 88 ms).

| Part | Tests |
|---|---|
| user-service (Java HttpServer, MySQL) | 26 |
| book-service (Python Flask, MongoDB) | 71 |
| order-service (Python Flask, MySQL) | 117 |
| Shared package `bookstore-ui` | 40 |
| Customer app (Mooney's) | 46 |
| Management app (Mooney's Manager) | 33 |
| **Total** | **333, all passing** |

| File | What it is |
|---|---|
| `Mooneys-Apps-Setup-1.1.0.exe` | Installs both apps for the current user (no administrator needed) |
| `Mooneys-Apps-1.1.0-portable.zip` | The same two apps, to unzip and run |
| `Mooneys-Server-1.1.0.zip` | The services and the whole source, with `user-service.jar` built; `setup.cmd`, `start-services.cmd`, `stop-services.cmd` |

### Added
- **Book reviews and ratings** in book-service: `GET /api/books/{id}/reviews`, `PUT /api/books/{id}/reviews/mine` (1 to 5 stars, up to 1000 characters of text), `DELETE /api/books/{id}/reviews/mine`. Any logged-in customer may review any book, once; the writer can edit or delete it; a manager cannot write one. Reviews are kept in the MongoDB collection `reviews`, with the unique index `one_review_per_customer_per_book` on (bookId, userId), created at start-up
- Every book now carries `ratingAverage` (one decimal, or null) and `ratingCount`, worked out from the reviews with one aggregation per search; never stored on the book
- **Mooney's**: stars and the review count on each book's card and in the list view; a Reviews section in a book's detail panel ("Your review" first with Edit and Delete, then the others, newest first); a dialog to write or edit a review, with a star picker and a character count; Delete has Undo
- **Sales report** in order-service: `GET /api/reports/sales?from=&to=&top=`, managers only. For the period (whole days, both ends included): how many orders, paid, and pending; revenue and paid revenue; books sold and rented; the orders themselves; sales by day, and the best sellers (default 10, at most 50). Worked out in Python from the period's orders
- **Mooney's Manager**: a third tab, **Reports**. Period buttons (Today, Last 7 days, Last 30 days, This month, All time), four tiles, a Sales by day bar chart with the amounts, the Best sellers table, and the orders in the period. F5 refreshes it
- Shared package: `Review`, `RatingStars`, `StarPicker`, `BookApi.reviews`, `saveMyReview`, `deleteMyReview`, `ApiClient.delete`, and multi-line text fields
- Screenshots: `customer-reviews-light.png`, `manager-reports-light.png`, `manager-reports-dark.png`
- The apps' live checks also write and delete a review, and compare the all-time report with the order list

### Changed
- The manager app's top bar: the logged-in name now shortens with an ellipsis, with the full name in a tooltip, so the bar fits with three tabs at any width (it overflowed at 1024 px)
- In the customer app's detail panel the reviews sit under Buy and Rent, and the panel scrolls; Buy and Rent are no longer pinned to the bottom of a tall window

### Fixed (found by the review before release, each with a test)
- book-service: a review sent with the book id in capital letters was stored under a second spelling, so one customer could review a book twice and those reviews were missing from the rating. Reviews are now stored under the book's own id
- order-service: best sellers tied on copies and revenue were ordered with capitals before lower case; now alphabetical whatever the case
- Customer app: the review dialog could be closed (Esc, a click outside) while a save was running; now it cannot. The character count counted UTF-16 units while book-service counts code points; now both count code points
- Manager app: the third tab made the top bar overflow at 1024 px, and the first fix (hiding the name below 1100 px) still overflowed with a long username at 1100 px and wider; now the name shortens with an ellipsis at any width

## v1.0.0 — 2026-11-17 — Mooney's: the final version (M5)

The submittable system. Every requirement FR1–FR14 and N1–N5 is met and tested ([requirements test report](docs/06-testing/requirements-test.md)), with every extra-credit item. The store now has a name, **Mooney's**, with shelves and real cover photos, at the owner's request. Install: [INSTALL.md](INSTALL.md). For the instructor: [HANDOVER.md](HANDOVER.md).

| Part | Tests |
|---|---|
| user-service (Java HttpServer, MySQL) | 26 |
| book-service (Python Flask, MongoDB) | 37 |
| order-service (Python Flask, MySQL) | 101 |
| Shared package `bookstore-ui` | 21 |
| Customer app (Mooney's) | 35 |
| Management app (Mooney's Manager) | 16 |
| **Total** | **236, all passing** |

| File | What it is |
|---|---|
| `Mooneys-Apps-Setup-1.0.0.exe` | Installs both apps for the current user (no administrator needed) |
| `Mooneys-Apps-1.0.0-portable.zip` | The same two apps, to unzip and run |
| `Mooneys-Server-1.0.0.zip` | The services and the whole source, with `user-service.jar` built; `setup.cmd`, `start-services.cmd`, `stop-services.cmd` |

### Added
- **Mooney's**: the store's name and sign, gold capitals on deep green, in the top bar of both apps, large on the login screens, on the bill and the email subject, in the window titles, the installer, and the Start menu
- **Shelves**: Fiction, Nonfiction, Kids, Science, Technology. A row of shelf tabs under the sign in the customer app; a shelf choice in the manager's book form and a Shelf column in the books list; `?category=` in book-service, which also requires a shelf for every book added or changed
- **Real cover photos** for every book, linked from Open Library; the drawn cover shows until the photo arrives, and stays without internet
- 12 general books, so every shelf has books (27 in all)
- `seed.py --if-empty` brings an existing catalog up to date (missing books, shelves, covers) without changing anything a manager did
- `tools/screenshots/fetch_covers.py` (cover photos for the screenshot tests, kept out of git) and `tools/diagrams/bill_sample.py`

### Changed
- In a narrow window, the search field drops its "Ctrl F" hint and the account button shows only its icon, so the search field keeps its room
- The release files are named `Mooneys-…`

## v1.0.0-beta.2 — 2026-11-17 — Tested on a second computer

The same apps and services as beta.1, made to be tested on a computer that has never seen the project. Installation: [INSTALL.md](INSTALL.md).

### Added
- `.github/workflows/fresh-machine-test.yml`: downloads a release onto a new GitHub Windows machine and follows INSTALL.md. It unzips the server, runs `setup.cmd`'s script twice, runs the 41 service checks, starts the services, installs the apps, opens both, and uninstalls
- `setup.ps1` takes the MySQL root password from `BOOKSTORE_MYSQL_ROOT_PASSWORD` when it is set, for automated tests only; a person is still asked by MySQL itself

### Fixed
- Links in the release notes are full addresses, so they work on the release page

## v1.0.0-beta.1 — 2026-11-17 — Installable build

The first build anyone can install without the development tools. Every requirement FR1–FR14 and N1–N5 is checked ([requirements test report](docs/06-testing/requirements-test.md)). Installation: [INSTALL.md](INSTALL.md).

| File | What it is |
|---|---|
| `Bookstore-Apps-Setup-1.0.0-beta.1.exe` | Installs both apps, Bookstore and Bookstore Manager, for the current user (no administrator needed) |
| `Bookstore-Apps-1.0.0-beta.1-portable.zip` | The same two apps, to unzip and run |
| `Bookstore-Server-1.0.0-beta.1.zip` | The services and the whole source, with `user-service.jar` already built |

A beta because the release builds of the apps are made on GitHub's Windows machine (this project's own computer cannot make them, P-017), and nobody had installed them on a second computer when this was published.

### Added
- `setup.cmd`, `start-services.cmd`, `stop-services.cmd` in the project folder: set up the services on a new computer (installing Java, Python, and MongoDB through winget when missing), start them, stop them. The only question asked is the MySQL root password, typed into MySQL's own prompt, once
- `HANDOVER.md`: for the instructor. How to install and try it, a five-minute walk through every requirement, where each piece of evidence is, extra credit claimed, and known limits
- `installer/test-installer.ps1`: on GitHub, before release, installs silently, checks every file and Start menu entry, opens both apps, and uninstalls
- `INSTALL.md`: installing on a new computer, the test accounts, and what to do when something goes wrong
- `.github/workflows/windows-release.yml`: on each version tag, runs every test, builds both apps in release mode, makes the installer (`installer/bookstore.iss`) and the zips, and attaches them to the release
- `database/check_setup.py`: says in plain words whether each database is ready
- `database/seed.py --if-empty`: loads the test data only if it is not there yet, so running setup again never resets data
- The requirements test report (`docs/06-testing`), and `manual_check.py` covering every order endpoint (41 checks)

### Changed
- user-service is version 1.0.0, and its jar is always `target/user-service.jar`

## v0.4.0 — 2026-11-17 — Desktop clients (M4)

Both desktop apps are built in Flutter on the three real services, and the owner has run both and tried every screen. The owner also asked for a customer account page and a pretend checkout, beyond the PRD; both are built. All 225 tests pass.

| Part | Tests | Verified |
|---|---|---|
| Customer app | 34 | Run by the owner; its service clients against the running services: my orders 64 ms, paying 44 ms |
| Management app | 15 | Run by the owner; its service clients against the running services: one order 17 ms |
| Shared package `bookstore-ui` | 18 | The service client against a small real web server |
| order-service | 101 | Including 9 against the real MySQL |
| user-service, book-service | 26, 31 | Unchanged since v0.3.0, run again |

### Added
- **Customer app** on the real services: log in, create an account (FR3), search as you type, covers or list view, buy or rent, review and place the order, the bill (FR1–FR8). Its service clients checked against the three running services
- Shared UI package: text fields with their problem under them, error messages, the toast with Undo, page transitions, the bill drawn in the app, the log-in layout, and money and date formatting
- Screenshots of every customer-app screen in the style guide, drawn with the real typefaces
- **Management app** on the real services: log in (managers only), every order with a Pending / Paid filter, mark as paid with Undo, an order's bill in the app and printed from the browser, search, add and edit books (FR1, FR2, FR8, FR9, FR11–FR14). Its service clients checked against the running services
- order-service: `GET /api/orders/{id}`, one order as JSON, for its customer or a manager; the order now includes the customer's email
- **Customer account page** (asked for by the owner, beyond the PRD): profile, preferences remembered per customer, rentals due back, every order with its bill
- **Pretend checkout** (asked for by the owner, beyond the PRD): "Pay now" on the bill and "Pay" on the account page mark the customer's own order paid. No card details
- order-service: `GET /api/orders/mine` and `POST /api/orders/{id}/pay`
- `.gitattributes` marks the Flutter-generated `windows/` folders as generated, so GitHub does not count their C++ and CMake as project code

### Changed
- The customer app's style preview on sample books is replaced by the real screens
- The rent price is worked out in whole cents, exactly as order-service charges it; amounts show thousands separators
- The log-in form, service clients, session, and book and order data moved from the customer app into the shared package, used by both apps
- The bill screen has a back arrow instead of a "Continue shopping" button, at the owner's request

### Known problems
- P-017: release builds are blocked by Windows Smart App Control; debug builds work

## v0.3.0 — 2026-11-17 — Backend services (M3)

All three backend services are built, tested, and verified running together against the real MySQL and MongoDB: 145 tests pass, every request answers well under the 500 ms limit (N1), and a real bill email was delivered through Gmail.

| Service | Tests | Verified on the running service |
|---|---|---|
| user-service (Java HttpServer, MySQL) | 26 | Login 85–255 ms, session check 7–19 ms |
| book-service (Python Flask, MongoDB) | 31 | 16 checks, 3–38 ms |
| order-service (Python Flask, MySQL) | 88 | 33 checks, 6–93 ms; one real email |

### Added
- **order-service**: place an order with books bought or rented, the HTML bill saved as a file and emailed in the background, the manager's order list, and the payment status (FR6–FR10, FR12, FR13), with 88 tests; verified on the running service with the other two (33 checks, first order after a cold start in 93 ms). A real bill email was sent through Gmail
- `services/order-service/manual_check.py`: starts all three services and checks every order endpoint for real; `email_check.py` sends one real bill email
- Class diagram and file map for order-service
- Engineering rules: documentation, layers, error handling, tests (`docs/02-design/engineering-rules.md`)
- `REFERENCES.md`: every third-party file, library, tool, and source, with its license
- MIT License for the project's own work (`LICENSE`)
- Enhancement log (`docs/03-problems/enhancement-log.md`): 30 improvements beyond the requirements, with reasons and measured effects
- Problem log extended with the problems the AI assistant caused or ran into, an index, and a list of known gaps
- Record of the development environment and how to reproduce it (`docs/05-setup/environment.md`)
- Class diagram and file map for the shared UI package
- Sample books loaded into MongoDB
- `CLAUDE.md`: the standing rules and the state of the project, so a new assistant session can carry on
- `tools/diagrams`: the scripts that generate the draw.io diagrams
- **book-service**: keyword search on title and author, add and update for managers, and a service-only endpoint for taking copies (FR4, FR5, FR6, FR14), with 31 tests; verified on the running service
- `database/make_local_setup.py`: generates a dedicated, limited MySQL account for the services, so the root password is never stored or shared
- **user-service**: login, logout, session check, and registration (FR1, FR2, FR3, FR11), with bcrypt password hashing, one error format, and 26 tests; verified against MySQL

### Fixed
- P-016: the bill email arrived in Gmail with a broken layout; the bill now uses tables instead of flex layout
- P-005: login was too close to the 500 ms limit against the real database; user-service now uses a connection pool and warms up at start-up (login 85–255 ms, session check 7–19 ms)
- P-004: the first request to a service by the name `localhost` took over 2 seconds; services now listen on both loopback addresses

### Changed
- Placing an order now takes the copies first and saves the order second, giving the copies back if anything fails (the design saved first). The response field `emailSent` is now `emailQueued`. API specification and the place-order sequence diagram updated
- `CatalogScreen` renamed `SearchScreen`, to match the class diagram
- Use case diagram: the mail server (Gmail) added as an external actor; actors defined in `use-cases.md`

### Not done in this version
- The two desktop apps: only the style preview of the search screen exists, on sample data (M4). This includes the register screen, the app half of FR3; issue #15 moved to M4
- Known gaps, listed at the end of the problem log: a copy is not given back if book-service's answer is lost; the order-service MySQL tests use up real order numbers; the bill email is checked in Gmail only; `uml.py` still writes three removed diagrams, and two M2 diagrams show the old order of placing an order

## v0.2.0 — 2026-11-13 — Design (M2)

The design phase is complete: how the system is built and how it looks are both decided.

### Added
- UML diagrams: class (apps and services), object, component, profile, use case, sequence, activity, state machine
- Written description of every use case (`docs/02-design/use-cases.md`)
- MySQL schema, 15 sample books, and a seed script (`database/`)
- Full API specification: request, response, and errors for every endpoint
- UI wireframes for both apps and a sample HTML bill
- The two Flutter desktop projects (`clients/customer-app`, `clients/management-app`) and a VS Code launch configuration for each
- Visual style guide with a working preview of the catalog screen in light and dark mode (`docs/02-design/style-guide.md`)
- Shared Flutter package `clients/bookstore-ui`: colors, type, glass panels, generated book covers, buttons, smooth scrolling
- Optional `coverUrl` field on books

### Decided
- Visual style of both apps: warm neutral colors where only the book covers carry color, glass panels, light and dark mode, Inter and Source Serif 4, color-blind safe, mapped to Nielsen's ten heuristics
- The search screen shows books as a grid of covers, with a list view as the alternative
- Placing an order reduces the available copies of each book
- order-service generates the bill and emails it; if the email fails, the order still succeeds

### Problems solved
- P-002: the first Flutter build was blocked by Windows security

### Not done in this version
- The database scripts have not been run (no database installed yet)
- Only the catalog screen exists, on sample data; no service is implemented

## v0.1.0 — 2026-11-13 — Idea and requirements (M1)

The idea phase is complete: what the system must do is agreed, and every open question is answered.

### Added
- Repository structure that records the process: idea, design, problem log, planning
- Requirements from the official PRD: functional (FR1–FR14), non-functional (technology, N1–N5), and assumptions
- Milestone plan with deadlines, GitHub issues as tasks, and versioning rules

### Decided
- Technology, as the PRD requires: Java HttpServer for user-service, Python Flask for book-service and order-service, MySQL and MongoDB
- Both desktop apps in Flutter, because UI/UX quality is the priority (first choice was JavaFX)
- Every extra-credit item is being done: registration (FR3), emailing the bill (FR10), modern GUI framework
- Renting rule: 10% of the book price, for 7 days
- Bill emails are sent through Gmail
- The project is done individually
- Final deadline 2026-12-04, with five milestones

### Problems solved
- P-001: the backend was first designed on Spring Boot, before the non-functional requirements were available

### Left out
- Features the PRD does not ask for: reviews, order history, deleting books, shipping statuses, categories
