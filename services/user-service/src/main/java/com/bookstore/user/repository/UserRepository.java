package com.bookstore.user.repository;

import com.bookstore.user.model.Role;
import com.bookstore.user.model.User;
import java.util.Optional;

/**
 * Reads and writes accounts.
 *
 * <p>An interface so that the rules in AuthService can be tested without a
 * database: {@link JdbcUserRepository} is the real one (MySQL),
 * {@link InMemoryUserRepository} is used by tests and by memory mode.
 */
public interface UserRepository {

    Optional<User> findByUsername(String username);

    Optional<User> findById(int id);

    /** True if an account already uses this username or this email. */
    boolean existsByUsernameOrEmail(String username, String email);

    /**
     * Stores a new account and returns it with its id.
     *
     * @throws com.bookstore.user.error.ConflictException if the username or email is already used
     */
    User save(String username, String email, String passwordHash, Role role);
}
