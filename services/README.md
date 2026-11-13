# Backend services

Each service is its own Spring Boot (Maven) project, added during milestone M3:

- `user-service/` — login, logout, sessions, roles (MySQL)
- `catalog-service/` — keyword search, add and update books (MongoDB)
- `order-service/` — orders, HTML bills, payment status (MySQL)

Design: [architecture](../docs/02-design/architecture.md), [API](../docs/02-design/api-design.md).
