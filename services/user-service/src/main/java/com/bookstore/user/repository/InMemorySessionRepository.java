package com.bookstore.user.repository;

import com.bookstore.user.model.Session;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

/** Sessions kept in memory instead of MySQL. See {@link InMemoryUserRepository}. */
public class InMemorySessionRepository implements SessionRepository {

    private final Map<String, Session> sessions = new ConcurrentHashMap<>();

    @Override
    public Session create(String token, int userId) {
        Session session = new Session(token, userId, LocalDateTime.now());
        sessions.put(token, session);
        return session;
    }

    @Override
    public Optional<Session> find(String token) {
        return Optional.ofNullable(sessions.get(token));
    }

    @Override
    public boolean delete(String token) {
        return sessions.remove(token) != null;
    }
}
