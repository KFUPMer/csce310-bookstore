package com.bookstore.user.http.dto;

import com.bookstore.user.model.User;

/**
 * What the service tells callers about a user. Never includes the password hash.
 *
 * <p>{@code token} is only filled in by login; it is {@code null} elsewhere.
 */
public record UserResponse(String token, int userId, String username, String email, String role) {

    public static UserResponse of(User user) {
        return new UserResponse(null, user.id(), user.username(), user.email(), user.role().name());
    }

    public static UserResponse withToken(User user, String token) {
        return new UserResponse(token, user.id(), user.username(), user.email(), user.role().name());
    }
}
