package com.bookstore.user.repository;

import com.bookstore.user.model.Session;
import java.util.Optional;

/** Reads and writes sessions. See {@link UserRepository} for why this is an interface. */
public interface SessionRepository {

    /** Stores a new session for the user and returns it. */
    Session create(String token, int userId);

    Optional<Session> find(String token);

    /** Ends a session. Returns false if there was no such session. */
    boolean delete(String token);
}
