# Milestones, tasks, and deadlines

The live version of this plan is on GitHub: milestones hold the deadlines, issues are the tasks.

## Milestones

| Milestone | Goal | Deadline | Release |
|---|---|---|---|
| M1 — Idea & Requirements | Scope and requirements agreed | 2026-11-15 | v0.1.0 — **released 2026-11-13** |
| M2 — Design | Architecture, database, API, and UI designed | 2026-11-19 | v0.2.0 — **released 2026-11-13** |
| M3 — Backend Services | All three services working against their databases | 2026-11-26 | v0.3.0 — **released 2026-11-17** |
| M4 — Desktop Clients | Both GUI apps working against the services | 2026-12-01 | v0.4.0 — **released 2026-11-17** |
| M5 — Testing & Final Release | Tested, documented, ready to submit | 2026-12-04 | v1.0.0 |

## Tasks

### M1 — Idea & Requirements (due 2026-11-15)

- [x] Record the requirements from the official PRD (FR1–FR14)
- [x] Record the non-functional requirements (technology, N1–N5)
- [x] Open questions resolved: individual project; bill emails through Gmail

### M2 — Design (due 2026-11-19)

- [x] UML diagrams: class, object, component, profile, use case, sequence, activity, state machine
- [x] Use case descriptions for all 14 use cases
- [x] MySQL schema, sample books, and seed script (to be run in M3)
- [x] REST API specification: request, response, and errors for all 13 endpoints
- [x] UI wireframes for both desktop apps
- [x] Bill layout (sample HTML bill)
- [x] Visual style of the two apps — [style-guide.md](../02-design/style-guide.md), approved

### M3 — Backend Services (due 2026-11-26)

- [x] Install Java 21, Maven, MongoDB, and the Python packages; load the books into MongoDB
- [x] Create the MySQL database, with a dedicated limited account for the services; load the test accounts
- [x] Create the book-service and order-service projects
- [x] user-service in Java HttpServer: login, logout, sessions, roles, bcrypt, registration (FR1, FR2, FR3, FR11, N3). 26 tests pass; verified against MySQL
- [x] book-service in Python Flask (31 tests, verified on the running service): keyword search, add and update books (FR4, FR5, FR14)
- [x] order-service in Python Flask (87 tests, verified on the running service): orders, HTML bill, order list, payment status (FR6–FR9, FR12, FR13)
- [x] Try the bill email for real through Gmail: sent and accepted by Gmail on 2026-11-16
- [x] Owner looks at the email in the inbox: the first showed a broken layout (P-016), the second, after the fix, looks as designed
- [x] Release v0.3.0

### M4 — Desktop Clients (due 2026-12-01)

- [x] Install Flutter and create the two desktop projects
- [x] customer-app in Flutter, asynchronous calls (N2): register (the app half of FR3, issue #15), login, search, select books, place order, see bill. Checked against the running services; the owner ran it and it works
- [x] management-app in Flutter, asynchronous calls (N2): login, orders list, payment status, an order's bill, add and update books (issue #12). 15 tests; checked against the running services; the owner tried it and everything works
- [x] Asked for by the owner, beyond the PRD: an account page in the customer app (order history, profile, preferences, rentals due back) and a pretend checkout that marks an order paid (no real card details). Checked against the running services; the owner tried it ("everything is alright")
- [x] Release v0.4.0

### M5 — Testing & Final Release (due 2026-12-04)

- [ ] Test every requirement FR1–FR14 and N1–N5 end to end
- [ ] Final documentation and release v1.0.0

### Extra credit (all being done, +4% in total)

- [x] FR3: user registration (+1%) — user-service (M3) and the register screen of the customer app (M4)
- [x] FR10: email the bill to the customer (+1%) — built in order-service; a real bill was sent through Gmail
- [x] Modern GUI framework (+2%) — both apps in Flutter (M4)

## Progress notes

Add a short dated note whenever a milestone closes or a deadline moves, and say why.

| Date | Note |
|---|---|
| 2026-11-13 | Repository created, initial plan drafted. |
| 2026-11-13 | Deadlines rescheduled to fit the final submission deadline of 2026-12-04. |
| 2026-11-13 | Official PRD received. Requirements, design docs, diagrams, and tasks corrected to match it. |
| 2026-11-13 | Non-functional requirements received. Backend stack changed from Spring Boot to Java HttpServer + Python Flask (see problem log P-001). Deadlines unchanged. |
| 2026-11-13 | UML diagrams drawn in draw.io (first drafts), ahead of the M2 deadline. Deployment, package, and composite structure diagrams were drawn and then dropped as not needed. |
| 2026-11-13 | Decided to do every extra-credit item. Use case descriptions, more sequence and activity diagrams, database scripts, API specification, wireframes, and bill layout drafted. Visual style of the apps still open. |
| 2026-11-13 | Client framework changed from JavaFX to Flutter because UI/UX quality is the priority. App class diagrams redrawn. Flutter is not installed yet. |
| 2026-11-13 | Flutter 3.50 and Visual Studio 2022 Build Tools installed; both empty apps compile and open a window. Done ahead of M4. |
| 2026-11-13 | **M1 closed, v0.1.0 released**, two days before its deadline. |
| 2026-11-13 | Visual style proposed from the owner's brief (Apple-like, glass, neutral colors, light and dark, color-blind safe, Nielsen heuristics) and built as a working preview of the catalog screen. Waiting for review before M2 closes. |
| 2026-11-13 | Visual style approved. **M2 closed, v0.2.0 released**, six days before its deadline. Next: M3, the backend services. |
| 2026-11-13 | M3 started. Java 21, Maven 3.9.9, and MongoDB 9.0 installed; books loaded into MongoDB and search checked. MySQL 8.0 was already installed; creating the database waits for the root password. Engineering rules written. |
| 2026-11-13 | user-service built: 27 classes in four layers, 26 tests passing, every endpoint called on the running service. Found and fixed a 2-second delay on the first request (P-004). Not yet run against MySQL. |
| 2026-11-13 | MySQL database created with a dedicated `bookstore_app` account; test accounts loaded. user-service verified against it. Measuring showed login too close to the 500 ms limit; fixed with a connection pool and a start-up warm-up (P-005). |
| 2026-11-16 | book-service built and verified: 31 tests, every endpoint checked on the running service with user-service and MongoDB, 3–38 ms per request. order-service is next. |
| 2026-11-16 | order-service built and verified: 87 tests, 33 checks on the three running services, 6–93 ms per request. A review before committing found ten things; five fixed, the rest recorded (P-015). All three services now work. M3 stays open until a bill has been emailed for real, which needs the owner's Gmail app password. |
| 2026-11-16 | A real bill was emailed through Gmail. The first one showed a broken layout in Gmail (P-016); after the fix the owner confirmed the second one looks right. |
| 2026-11-17 | **M3 closed, v0.3.0 released**, nine days before its deadline. All 145 tests pass. Issue #15 (registration) moved to M4, because its remaining half is the register screen. Next: M4, the two desktop apps. |
| 2026-11-17 | Customer app built on the real services: five screens, 41 tests, every screen drawn into the style guide. Release builds are blocked by Smart App Control (P-017); debug builds work. Next: the owner tries the app; then the management app. |
| 2026-11-17 | The owner ran the customer app: it works. They asked for an account page and a way to pay; decided to build the management app first. Management app built: shared log-in and service clients moved into `bookstore-ui`, a new `GET /api/orders/{id}` in order-service (92 tests), 15 app tests, checked against the running services. Next: the owner tries it; then the account page and the pretend checkout. |
| 2026-11-17 | The owner tried the management app: "everything seems good". Issue #12 closed. Next: the account page and the pretend checkout. |
| 2026-11-17 | Account page and pretend checkout built: two new order-service endpoints (101 tests), 34 customer-app tests, checked against the running services. Next: the owner tries them; then M5, testing every requirement end to end. |
| 2026-11-17 | The owner tried the account page and checkout: "everything is alright". At their request the bill screen's "Continue shopping" button became a back arrow, as on the account page. |
| 2026-11-17 | **M4 closed, v0.4.0 released**, two weeks before its deadline. All 225 tests pass. Issues #11 and #15 closed. Next: M5, testing every requirement end to end. |
