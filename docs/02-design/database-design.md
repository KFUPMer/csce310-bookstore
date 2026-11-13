# Phase 2 — Database design

> Status: **proposed starting point**. To be finalized in milestone M2.

## MySQL (users and orders)

```mermaid
erDiagram
    USERS ||--o{ ORDERS : places
    ORDERS ||--|{ ORDER_ITEMS : contains

    USERS {
        int id PK
        varchar email UK
        varchar password_hash
        varchar full_name
        enum role "CUSTOMER or STAFF"
        datetime created_at
    }
    ORDERS {
        int id PK
        int user_id FK
        enum status "PENDING, PAID, SHIPPED, CANCELLED"
        decimal total
        datetime created_at
    }
    ORDER_ITEMS {
        int id PK
        int order_id FK
        varchar book_id "MongoDB book id"
        int quantity
        decimal unit_price "price at time of order"
    }
```

## MongoDB (catalog)

Collection `books`:

```json
{
  "_id": "ObjectId",
  "isbn": "9780000000000",
  "title": "Example Title",
  "authors": ["Author Name"],
  "categories": ["Fiction"],
  "price": 19.99,
  "stock": 12,
  "description": "…",
  "reviews": [
    { "userId": 5, "rating": 4, "comment": "…", "createdAt": "2026-11-13T00:00:00Z" }
  ]
}
```

## Notes

- `ORDER_ITEMS.book_id` points to a MongoDB document, so there is no foreign key across databases. The order service must validate the book through the catalog service.
- `unit_price` is copied into the order so later price changes do not alter past orders.

## Still to do in M2

- [ ] Normalization check for the MySQL schema
- [ ] Indexes (MySQL and MongoDB)
- [ ] SQL schema script and seed data
