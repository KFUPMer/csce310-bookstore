# Milestones, tasks, and deadlines

The live version of this plan is on GitHub: milestones hold the deadlines, issues are the tasks.

## Milestones

| Milestone | Goal | Deadline | Release |
|---|---|---|---|
| M1 — Idea & Requirements | Scope and requirements agreed | 2026-11-15 | v0.1.0 |
| M2 — Design | Architecture, database, API, and UI designed | 2026-11-19 | v0.2.0 |
| M3 — Backend Services | All three services working against their databases | 2026-11-26 | v0.3.0 |
| M4 — Desktop Clients | Both GUI apps working against the services | 2026-12-01 | v0.4.0 |
| M5 — Testing & Final Release | Tested, documented, ready to submit | 2026-12-04 | v1.0.0 |

## Tasks

### M1 — Idea & Requirements (due 2026-11-15)

- [x] Record the requirements from the official PRD (FR1–FR14)
- [x] Record the non-functional requirements (technology, N1–N5)
- [ ] Resolve the remaining open questions

### M2 — Design (due 2026-11-19)

- [ ] Use case and sequence diagrams
- [ ] Finalize MySQL schema and MongoDB document model
- [ ] Finalize REST API specification
- [ ] UI wireframes for both desktop apps

### M3 — Backend Services (due 2026-11-26)

- [ ] Set up the three service projects (Java, Python) and local MySQL/MongoDB
- [ ] user-service in Java HttpServer: login, logout, sessions, roles, bcrypt (FR1, FR2, FR11, N3)
- [ ] book-service in Python Flask: keyword search, add and update books (FR4, FR5, FR14)
- [ ] order-service in Python Flask: orders, HTML bill, order list, payment status (FR6–FR9, FR12, FR13)

### M4 — Desktop Clients (due 2026-12-01)

- [ ] customer-app in JavaFX, asynchronous calls (N2): login, search, select books, place order, see bill
- [ ] management-app in JavaFX, asynchronous calls (N2): login, orders list, payment status, add and update books

### M5 — Testing & Final Release (due 2026-12-04)

- [ ] Test every requirement FR1–FR14 and N1–N5 end to end
- [ ] Final documentation and release v1.0.0

### Optional (extra credit, only if time allows)

- [ ] FR3: user registration (+1%)
- [ ] FR10: email the bill to the customer (+1%)

## Progress notes

Add a short dated note whenever a milestone closes or a deadline moves, and say why.

| Date | Note |
|---|---|
| 2026-11-13 | Repository created, initial plan drafted. |
| 2026-11-13 | Deadlines rescheduled to fit the final submission deadline of 2026-12-04. |
| 2026-11-13 | Official PRD received. Requirements, design docs, diagrams, and tasks corrected to match it. |
| 2026-11-13 | Non-functional requirements received. Backend stack changed from Spring Boot to Java HttpServer + Python Flask (see problem log P-001). Deadlines unchanged. |
