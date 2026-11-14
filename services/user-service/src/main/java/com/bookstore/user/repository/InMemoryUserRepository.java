package com.bookstore.user.repository;

import com.bookstore.user.error.ConflictException;
import com.bookstore.user.model.Role;
import com.bookstore.user.model.User;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Accounts kept in memory instead of MySQL.
 *
 * <p>For tests and for memory mode (STORAGE=memory), where the service runs
 * without a database. Everything is lost when the service stops.
 */
public class InMemoryUserRepository implements UserRepository {

    private final Map<Integer, User> users = new ConcurrentHashMap<>();
    private final AtomicInteger nextId = new AtomicInteger(1);

    @Override
    public Optional<User> findByUsername(String username) {
        return users.values().stream().filter(u -> u.username().equals(username)).findFirst();
    }

    @Override
    public Optional<User> findById(int id) {
        return Optional.ofNullable(users.get(id));
    }

    @Override
    public boolean existsByUsernameOrEmail(String username, String email) {
        return users.values().stream().anyMatch(u -> u.username().equals(username) || u.email().equalsIgnoreCase(email));
    }

    @Override
    public synchronized User save(String username, String email, String passwordHash, Role role) {
        if (existsByUsernameOrEmail(username, email)) {
            throw new ConflictException("Username or email already in use");
        }
        User user = new User(nextId.getAndIncrement(), username, email, passwordHash, role, LocalDateTime.now());
        users.put(user.id(), user);
        return user;
    }
}
