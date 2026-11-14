package com.bookstore.user.model;

import java.time.LocalDateTime;

/**
 * An account, as stored in the USERS table.
 *
 * <p>{@code passwordHash} is a bcrypt hash. The plain password is never stored
 * and never leaves the service layer (N3).
 */
public record User(int id, String username, String email, String passwordHash, Role role, LocalDateTime createdAt) {
}
