# Changelog

All versions and patches of the project, newest first.

## Unreleased

Work towards v1.0.0 (milestone M5, Testing & final release).

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
