# Changelog

All versions and patches of the project, newest first.

## Unreleased

Work towards v0.3.0 (milestone M3, Backend services).

### Added
- Engineering rules: documentation, layers, error handling, tests (`docs/02-design/engineering-rules.md`)
- `REFERENCES.md`: every third-party file, library, tool, and source, with its license
- Enhancement log (`docs/03-problems/enhancement-log.md`): 20 improvements beyond the requirements, with reasons and measured effects
- Problem log extended with the problems the AI assistant caused or ran into, an index, and a list of known gaps
- Record of the development environment and how to reproduce it (`docs/05-setup/environment.md`)
- Class diagram and file map for the shared UI package
- Sample books loaded into MongoDB
- `database/make_local_setup.py`: generates a dedicated, limited MySQL account for the services, so the root password is never stored or shared
- **user-service**: login, logout, session check, and registration (FR1, FR2, FR3, FR11), with bcrypt password hashing, one error format, and 26 tests; verified against MySQL

### Fixed
- P-005: login was too close to the 500 ms limit against the real database; user-service now uses a connection pool and warms up at start-up (login 85–255 ms, session check 7–19 ms)
- P-004: the first request to a service by the name `localhost` took over 2 seconds; services now listen on both loopback addresses

### Changed
- `CatalogScreen` renamed `SearchScreen`, to match the class diagram
- Use case diagram: the mail server (Gmail) added as an external actor; actors defined in `use-cases.md`

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
