package com.bookstore.user.http.dto;

import com.bookstore.user.error.ValidationException;
import java.util.regex.Pattern;

/** The body of POST /api/users/register (FR3). */
public record RegisterRequest(String username, String email, String password) {

    public static final int USERNAME_MIN = 3;
    public static final int USERNAME_MAX = 50;
    public static final int PASSWORD_MIN = 8;
    /** bcrypt only uses the first 72 bytes of a password, so longer ones are refused rather than silently cut. */
    public static final int PASSWORD_MAX = 72;

    private static final Pattern USERNAME = Pattern.compile("[A-Za-z0-9._-]+");
    /** Something, an @, something, a dot, something. Enough to catch typing mistakes. */
    private static final Pattern EMAIL = Pattern.compile("[^@\\s]+@[^@\\s]+\\.[^@\\s]+");

    /** @throws ValidationException naming the first field that is missing or not acceptable */
    public void validate() {
        if (username == null || username.isBlank()) {
            throw new ValidationException("Enter a username");
        }
        if (username.length() < USERNAME_MIN || username.length() > USERNAME_MAX) {
            throw new ValidationException("The username must be " + USERNAME_MIN + " to " + USERNAME_MAX + " characters long");
        }
        if (!USERNAME.matcher(username).matches()) {
            throw new ValidationException("The username can only contain letters, digits, dots, dashes, and underscores");
        }
        if (email == null || email.isBlank()) {
            throw new ValidationException("Enter an email address");
        }
        if (email.length() > 255 || !EMAIL.matcher(email).matches()) {
            throw new ValidationException("Enter a valid email address");
        }
        if (password == null || password.isEmpty()) {
            throw new ValidationException("Enter a password");
        }
        if (password.length() < PASSWORD_MIN) {
            throw new ValidationException("The password must be at least " + PASSWORD_MIN + " characters long");
        }
        if (password.getBytes(java.nio.charset.StandardCharsets.UTF_8).length > PASSWORD_MAX) {
            throw new ValidationException("The password is too long");
        }
    }
}
