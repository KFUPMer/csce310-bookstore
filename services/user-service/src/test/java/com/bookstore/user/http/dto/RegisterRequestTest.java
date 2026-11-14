package com.bookstore.user.http.dto;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.bookstore.user.error.ValidationException;
import org.junit.jupiter.api.Test;

/** What a registration request must contain (FR3). */
class RegisterRequestTest {

    @Test
    void aCompleteRequestIsAccepted() {
        assertDoesNotThrow(() -> new RegisterRequest("alice_1", "alice@example.com", "eightchr").validate());
    }

    @Test
    void everyFieldIsRequired() {
        assertRefused(new RegisterRequest(null, "a@b.co", "longenough"), "username");
        assertRefused(new RegisterRequest("alice", null, "longenough"), "email");
        assertRefused(new RegisterRequest("alice", "a@b.co", null), "password");
        assertRefused(new RegisterRequest("  ", "a@b.co", "longenough"), "username");
    }

    @Test
    void theUsernameMustBeThreeToFiftySafeCharacters() {
        assertRefused(new RegisterRequest("ab", "a@b.co", "longenough"), "username");
        assertRefused(new RegisterRequest("a".repeat(51), "a@b.co", "longenough"), "username");
        assertRefused(new RegisterRequest("al ice", "a@b.co", "longenough"), "username");
        assertRefused(new RegisterRequest("alice'; DROP", "a@b.co", "longenough"), "username");
    }

    @Test
    void theEmailMustLookLikeAnEmail() {
        assertRefused(new RegisterRequest("alice", "not-an-email", "longenough"), "email");
        assertRefused(new RegisterRequest("alice", "a@b", "longenough"), "email");
        assertRefused(new RegisterRequest("alice", "a b@c.de", "longenough"), "email");
    }

    @Test
    void thePasswordMustBeEightToSeventyTwoBytes() {
        assertRefused(new RegisterRequest("alice", "a@b.co", "short"), "password");
        assertRefused(new RegisterRequest("alice", "a@b.co", "x".repeat(73)), "password");
    }

    private static void assertRefused(RegisterRequest request, String fieldInMessage) {
        ValidationException error = assertThrows(ValidationException.class, request::validate);
        assertTrue(error.getMessage().toLowerCase().contains(fieldInMessage), "message should name the " + fieldInMessage + ": " + error.getMessage());
    }
}
