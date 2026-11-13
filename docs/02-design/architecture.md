# Phase 2 — Architecture

> Status: **draft**, based on the official PRD. To be finalized in milestone M2.

## Overview

![System architecture](diagrams/architecture.png)

Source: [diagrams/architecture.drawio](diagrams/architecture.drawio)

## Services

| Service | Responsibility | Requirements | Database | Port |
|---|---|---|---|---|
| user-service | Login, logout, sessions, roles, (optional) registration | FR1, FR2, FR3, FR11 | MySQL | 8081 |
| catalog-service | Search books, add books, update book information | FR4, FR5, FR14 | MongoDB | 8082 |
| order-service | Create orders, generate and save the HTML bill, list orders, update payment status, (optional) email the bill | FR6–FR10, FR12, FR13 | MySQL | 8083 |

## Clients

| Client | User | Screens | Requirements |
|---|---|---|---|
| customer-app | Customer | Login, search and results list, selected books, bill confirmation | FR1, FR2, FR4–FR8 |
| management-app | Manager | Login, orders list with payment status, book add/update | FR11–FR14 |

## How a session works (FR1, FR2)

1. The client sends username and password to user-service.
2. user-service checks the password hash and returns a **session token**.
3. The client sends that token with every later request.
4. catalog-service and order-service ask user-service whether the token is valid and which role it belongs to.
5. Logging out deletes the session, so the token stops working.

Manager-only actions are refused unless the session belongs to a manager (FR11).

## How an order becomes a bill (FR7–FR9)

1. The customer app sends the selected books to order-service.
2. order-service gets each book's current price from catalog-service and checks copies are available. A bought book is charged at full price; a rented book at 10% of the price, due back in 7 days.
3. order-service saves the order in MySQL with payment status `PENDING`.
4. order-service writes the bill to `bills/bill-<orderId>.html` and returns it to the customer app.

## Why each database

- **MySQL** for users, sessions, and orders: fixed structure with relationships, and an order must be saved as one transaction.
- **MongoDB** for the book catalog: simple documents that are searched by keyword far more often than they are changed.

## Design decisions

| # | Date | Decision | Alternatives considered | Reason |
|---|---|---|---|---|
| 1 | 2026-11-13 | Spring Boot for services | Plain Java servlets, Python Flask | Standard for Java REST APIs; built-in MySQL and MongoDB support |
| 2 | 2026-11-13 | JavaFX for clients | Swing | More modern UI toolkit; layout is separate from logic |
| 3 | 2026-11-13 | Session token stored in MySQL | JWT | Simple to explain, and logout really ends the session (FR2) |
| 4 | 2026-11-13 | order-service generates the bill | A separate billing service | The bill is made at the moment the order is created; one less service |

## Still to design in M2

- [ ] Use case diagram
- [ ] Sequence diagram for "place an order"
- [ ] Class diagrams per service
- [ ] UI wireframes for both clients
