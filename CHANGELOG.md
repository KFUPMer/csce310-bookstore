# Changelog

All versions and patches of the project, newest first.

## Unreleased

### Added
- Repository structure for process documentation: idea, design, problem log, planning
- Draft project idea, proposed architecture, database design, and API design
- Milestone plan and versioning rules
- UML diagrams: class (apps and services), object, component, profile, use case, sequence, activity, state machine
- Design diagrams drawn in draw.io, with sources and exported images in `docs/02-design/diagrams`
- Written description of every use case (`docs/02-design/use-cases.md`)
- Sequence diagrams for log in, register, and updating payment status; activity diagrams for log in and for the manager
- MySQL schema, 15 sample books, and a seed script (`database/`)
- Full API specification: request, response, and errors for every endpoint
- UI wireframes for both apps and a sample HTML bill
- The two Flutter desktop projects (`clients/customer-app`, `clients/management-app`) and a VS Code launch configuration for each

### Changed
- Registration (FR3) and emailing the bill (FR10) are no longer optional: every extra-credit item is being done
- Placing an order now reduces the available copies of each book
- Desktop apps switched from JavaFX to Flutter, because UI/UX quality is the priority; app class diagrams redrawn
- Requirements replaced with the official PRD (FR1–FR14); design docs, diagrams, and tasks corrected to match
- Roles are now Customer and Manager; login uses username and a session
- Orders now carry a payment status (Pending/Paid) and produce an HTML bill
- Milestone deadlines moved to fit the 2026-12-04 submission deadline
- Renting rule defined: 10% of the book price for 7 days; rent price is calculated, not stored per book
- Non-functional requirements recorded (technology, N1–N5)
- PRD assumptions recorded: seed data is required for testing; no real payment processing
- Backend stack changed to what the PRD requires: Java HttpServer for user-service, Python Flask for book-service and order-service; `catalog-service` renamed `book-service`

### Removed
- Features the PRD does not ask for: reviews, order history, deleting books, shipping statuses, categories
