-- Bookstore: MySQL schema
-- Used by user-service (users, sessions) and order-service (orders, order_items).
-- Run:  mysql -u root -p < database/mysql/schema.sql

CREATE DATABASE IF NOT EXISTS bookstore
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE bookstore;

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS sessions;
DROP TABLE IF EXISTS users;

-- FR1, FR3, FR11, N3
CREATE TABLE users (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  username      VARCHAR(50)  NOT NULL UNIQUE,
  email         VARCHAR(255) NOT NULL UNIQUE,
  password_hash CHAR(60)     NOT NULL,              -- bcrypt, never the plain password
  role          ENUM('CUSTOMER', 'MANAGER') NOT NULL DEFAULT 'CUSTOMER',
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- FR2, N4: one row per logged-in session; deleted on logout
CREATE TABLE sessions (
  token      CHAR(64) PRIMARY KEY,                  -- random, sent by the client with every request
  user_id    INT      NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_sessions_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

-- FR7, FR8, FR12, FR13
CREATE TABLE orders (
  id             INT AUTO_INCREMENT PRIMARY KEY,    -- the unique order ID printed on the bill
  user_id        INT            NOT NULL,
  payment_status ENUM('PENDING', 'PAID') NOT NULL DEFAULT 'PENDING',
  total          DECIMAL(10, 2) NOT NULL,
  bill_file      VARCHAR(255)   NULL,               -- e.g. bills/bill-1042.html
  created_at     DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_orders_user FOREIGN KEY (user_id) REFERENCES users (id),
  INDEX idx_orders_created (created_at)
) AUTO_INCREMENT = 1001;

-- FR6, FR7, FR8
CREATE TABLE order_items (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  order_id      INT            NOT NULL,
  book_id       CHAR(24)       NOT NULL,            -- MongoDB _id of the book (no foreign key across databases)
  title         VARCHAR(255)   NOT NULL,            -- copied, so the bill stays correct if the book changes
  author        VARCHAR(255)   NOT NULL,
  type          ENUM('BUY', 'RENT') NOT NULL,
  quantity      INT            NOT NULL DEFAULT 1,
  unit_price    DECIMAL(10, 2) NOT NULL,            -- what was charged: price for BUY, 10% of price for RENT
  rent_due_date DATE           NULL,                -- order date + 7 days for RENT, NULL for BUY
  CONSTRAINT fk_items_order FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
  CONSTRAINT chk_quantity CHECK (quantity > 0),
  CONSTRAINT chk_rent_due CHECK ((type = 'RENT') = (rent_due_date IS NOT NULL))
);
