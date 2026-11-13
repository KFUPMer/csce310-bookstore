# Backend services

Each service is its own project, added during milestone M3. The technology of each one is fixed by the PRD (section 4.1).

| Folder | Built with | Does | Database |
|---|---|---|---|
| `user-service/` | Java HttpServer (Maven) | Login, logout, sessions, roles | MySQL |
| `book-service/` | Python Flask | Keyword search, add and update books | MongoDB |
| `order-service/` | Python Flask | Orders, HTML bills, payment status | MySQL |

Design: [architecture](../docs/02-design/architecture.md), [API](../docs/02-design/api-design.md).
