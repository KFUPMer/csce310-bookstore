package com.bookstore.user.model;

import java.time.LocalDateTime;

/**
 * One logged-in session, as stored in the SESSIONS table.
 *
 * <p>The token is what the apps send with every request. A session exists from
 * login until logout (FR2); deleting the row ends it.
 */
public record Session(String token, int userId, LocalDateTime createdAt) {
}
