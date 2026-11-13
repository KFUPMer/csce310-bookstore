# Changelog

All versions and patches of the project, newest first.

## Unreleased

### Added
- Repository structure for process documentation: idea, design, problem log, planning
- Draft project idea, proposed architecture, database design, and API design
- Milestone plan and versioning rules
- Class diagrams for the customer app and the manager app
- Design diagrams drawn in draw.io, with sources and exported images in `docs/02-design/diagrams`

### Changed
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
