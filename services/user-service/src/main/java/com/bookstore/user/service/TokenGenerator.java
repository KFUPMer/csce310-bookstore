package com.bookstore.user.service;

import java.security.SecureRandom;
import java.util.HexFormat;

/**
 * Makes session tokens.
 *
 * <p>A token is 32 random bytes from a cryptographic random source, written as
 * 64 hex characters. It cannot be guessed, and it says nothing about the user.
 */
public class TokenGenerator {

    private static final int BYTES = 32;

    private final SecureRandom random = new SecureRandom();

    public String newToken() {
        byte[] bytes = new byte[BYTES];
        random.nextBytes(bytes);
        return HexFormat.of().formatHex(bytes);
    }
}
