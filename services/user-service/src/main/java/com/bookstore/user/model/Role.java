package com.bookstore.user.model;

/** What a user is allowed to do. The PRD defines exactly these two roles. */
public enum Role {
    /** Searches for books and places orders, through the customer app. */
    CUSTOMER,
    /** Manages books, sees all orders, updates payment status, through the management app. */
    MANAGER
}
