# Phase 1 — Idea and requirements

Source: the official CSCE310 Product Requirements Document, "Online Bookstore with Desktop Application".

## The idea

An online business sells books. Customers use a desktop application to find books and order them. Managers use a second desktop application to manage books, see orders, and record payments.

The system has:

- Several backend **RESTful API web services** (Java HttpServer and Python Flask, as the PRD requires)
- A **MySQL** database and a **MongoDB** database
- **Two native desktop GUI applications**, not web pages (we use JavaFX)

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

## Renting rule (FR7)

- Renting a book costs **10% of the book's price**.
- A rental lasts **7 days**.

Example: a customer selects three books and places one order.

| Book | Choice | Book price | Charged |
|---|---|---|---|
| Clean Code | Buy | $40.00 | $40.00 |
| Database Systems | Buy | $55.00 | $55.00 |
| Java Concurrency | Rent (due back in 7 days) | $80.00 | $8.00 |
| **Total on the bill** | | | **$103.00** |

Handling the return of a rented book is not part of the PRD and is not built.

## Non-functional requirements

### Technology the PRD requires

| Part | Must be built with | Data stored in |
|---|---|---|
| User services (login, logout, create user) | Java HttpServer | MySQL |
| Book services (search, add, update) | Python Flask | MongoDB |
| Order and billing services (create order, update payment status) | Python Flask | MySQL |
| Customer app and Manager app (two separate programs) | Native desktop GUI. Default is Java Swing; a modern framework such as JavaFX earns +2% | — |

This is a client/server system, **not a web application**: the clients are desktop programs and do not run in a browser.

### Quality requirements

| ID | Requirement | In simple words |
|---|---|---|
| N1 | API endpoints respond to typical requests in under 500 ms | The services must be fast |
| N2 | The desktop client stays responsive during network operations; calls to the backend are asynchronous | The window must never freeze while waiting for the server |
| N3 | Passwords are stored with a strong one-way hash (e.g. bcrypt) | Nobody can read a password from the database |
| N4 | Every endpoint that handles user data or actions requires a valid authentication token | No token, no access |
| N5 | Users only access their own data; managers cannot do customer actions and customers cannot do manager actions | Each role is limited to its own job |

## Not required by the PRD

These were in the first draft of this document and have been removed because the PRD does not ask for them:

- Book reviews and ratings (the PRD mentions them only as an example of what a book service could do; no functional requirement asks for them)
- Customer order history
- Deleting books
- Shipping or cancelled order statuses
- Book categories

## Open questions

- [ ] Is the project individual or a team project?
- [ ] Are the two optional requirements (FR3, FR10) going to be done?

## Decisions made in this phase

| Date | Decision | Reason |
|---|---|---|
| 2026-11-13 | Use Java for backend and clients | One language across the whole system; personal preference. **Replaced below.** |
| 2026-11-13 | Requirements replaced with the official PRD (FR1–FR14) | The first draft was a guess made before the PRD was available |
| 2026-11-13 | Renting costs 10% of the book price and lasts 7 days | Rule given for FR7, which the PRD leaves undefined |
| 2026-11-13 | Backend follows PRD section 4.1: Java HttpServer for users, Python Flask for books and for orders | The PRD fixes the technology of each service, so "Java everywhere" is not allowed |
| 2026-11-13 | Both clients in JavaFX | Still Java, and a modern GUI framework earns +2% over Swing |
