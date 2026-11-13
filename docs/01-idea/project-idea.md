# Phase 1 — Idea and requirements

Source: the official CSCE310 Product Requirements Document, "Online Bookstore with Desktop Application".

## The idea

An online business sells books. Customers use a desktop application to find books and order them. Managers use a second desktop application to manage books, see orders, and record payments.

The system has:

- Several backend **RESTful API web services** (we use Java)
- A **MySQL** database and a **MongoDB** database
- **Two desktop GUI applications** (we use Java)

## User roles

| Role | Who they are | What they do |
|---|---|---|
| Customer | A registered user who wants books | Log in, search the catalog, place orders |
| Manager | An administrative user | Log in to a separate interface, manage books, view orders, update payment status |

## Functional requirements

| ID | Requirement | Area | Required? |
|---|---|---|---|
| FR1 | A registered user logs in with username and password; the system authenticates them and starts a session | Accounts | Yes |
| FR2 | The user stays logged in until they log out; every protected action is tied to their session | Accounts | Yes |
| FR3 | A new user can create an account with username, password, and a valid email; passwords are hashed on the backend | Accounts | Optional (+1%) |
| FR4 | A logged-in user searches books by a keyword, matched against both title and author | Catalog | Yes |
| FR5 | Search results are shown as a clear list with at least title, author, and price | Catalog | Yes |
| FR6 | A logged-in user selects one or more books from the search results | Ordering | Yes |
| FR7 | The user finalizes the selection, to buy and/or rent, in a single transaction that creates an order | Ordering | Yes |
| FR8 | Placing an order generates a detailed bill: unique order ID, list of items, individual prices, total amount due | Billing | Yes |
| FR9 | The bill is automatically saved as an HTML file (the manager can print it and post it to the customer) | Billing | Yes |
| FR10 | The bill is automatically emailed to the customer | Billing | Optional (+1%) |
| FR11 | Managers have a separate, secure management interface, distinct from the customer role | Manager | Yes |
| FR12 | A logged-in manager views a list of all purchase orders | Manager | Yes |
| FR13 | The manager selects an order and updates its payment status (e.g. Pending → Paid) | Manager | Yes |
| FR14 | The manager adds new books or updates their information (e.g. number of available copies) | Manager | Yes |

## Non-functional requirements

To be written later. They will be kept short and simple.

## Not required by the PRD

These were in the first draft of this document and have been removed because the PRD does not ask for them:

- Book reviews and ratings
- Customer order history
- Deleting books
- Shipping or cancelled order statuses
- Book categories

## Open questions

- [ ] **Renting:** FR7 says "buy and/or rent", but nothing else in the PRD describes renting (rental price, return, duration). Ask the instructor. Until answered, the design keeps a simple `BUY` / `RENT` type on each ordered book.
- [ ] Is the project individual or a team project?
- [ ] Are the two optional requirements (FR3, FR10) going to be done?

## Decisions made in this phase

| Date | Decision | Reason |
|---|---|---|
| 2026-11-13 | Use Java for backend and clients | One language across the whole system; personal preference |
| 2026-11-13 | Requirements replaced with the official PRD (FR1–FR14) | The first draft was a guess made before the PRD was available |
