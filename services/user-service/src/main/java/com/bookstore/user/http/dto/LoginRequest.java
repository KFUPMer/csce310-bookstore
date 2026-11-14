package com.bookstore.user.http.dto;

import com.bookstore.user.error.ValidationException;

/** The body of POST /api/auth/login. */
public record LoginRequest(String username, String password) {

    /** @throws ValidationException naming the first missing field */
    public void validate() {
        if (username == null || username.isBlank()) {
            throw new ValidationException("Enter your username");
        }
        if (password == null || password.isEmpty()) {
            throw new ValidationException("Enter your password");
        }
    }
}
