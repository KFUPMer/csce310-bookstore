package com.bookstore.user.service;

import org.mindrot.jbcrypt.BCrypt;

/**
 * Hashes passwords with bcrypt and checks a password against a hash (N3).
 *
 * <p>bcrypt is one-way and slow on purpose: a stolen database does not reveal
 * the passwords, and guessing them takes a long time. Each hash contains its
 * own random salt, so two users with the same password get different hashes.
 */
public class PasswordHasher {

    /** Work factor: each step up doubles the time to hash. 10 is the common default. */
    private static final int COST = 10;

    public String hash(String password) {
        return BCrypt.hashpw(password, BCrypt.gensalt(COST));
    }

    public boolean matches(String password, String hash) {
        try {
            return BCrypt.checkpw(password, hash);
        } catch (IllegalArgumentException e) {
            // The stored value is not a bcrypt hash. Treat as "does not match" rather than crash.
            return false;
        }
    }
}
