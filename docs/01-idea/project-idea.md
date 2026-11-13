# Phase 1 — Idea

> Status: **draft**. Everything marked "proposed" must be checked against the official CSCE310 project description before M1 is closed.

## Problem statement

A bookstore needs to manage its catalog, customers, and orders. Customers need a way to browse and buy books; staff need a way to manage inventory and orders.

## What the course requires

- Several backend **RESTful API web services** (Java or Python Flask — we chose Java)
- Both a **MySQL** database and a **MongoDB** database
- **Two client-facing desktop GUI applications** in a modern language (we chose Java)

## Proposed scope

### Users (proposed)

| User | Uses | Goal |
|---|---|---|
| Customer | Customer desktop app | Browse, search, and order books |
| Staff / admin | Management desktop app | Manage books, stock, and orders |

### Functional requirements (proposed)

| ID | Requirement | Priority |
|---|---|---|
| FR-1 | Register and log in | Must |
| FR-2 | Browse and search the book catalog | Must |
| FR-3 | View book details | Must |
| FR-4 | Add books to a cart and place an order | Must |
| FR-5 | View order history | Should |
| FR-6 | Staff: add, edit, remove books | Must |
| FR-7 | Staff: update stock levels | Must |
| FR-8 | Staff: view and update order status | Should |
| FR-9 | Book reviews and ratings | Could |

### Non-functional requirements (proposed)

- Clients never touch the databases directly; all access goes through the REST services.
- Passwords are stored hashed, never in plain text.
- Each service can be started and tested on its own.

## Out of scope

- Real payment processing
- Web or mobile clients
- Deployment to the cloud

## Open questions

- [ ] What exactly does the course spec require for each client application?
- [ ] Is there a required minimum number of services or endpoints?
- [ ] Is the project individual or a team project?
- [ ] What are the official submission deadlines?

## Decisions made in this phase

| Date | Decision | Reason |
|---|---|---|
| 2026-11-13 | Use Java for backend and clients | One language across the whole system; personal preference |
