package com.bookstore.user.repository;

import com.bookstore.user.error.ConflictException;
import com.bookstore.user.error.DataAccessException;
import com.bookstore.user.model.Role;
import com.bookstore.user.model.User;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.SQLIntegrityConstraintViolationException;
import java.sql.Statement;
import java.util.Optional;

/**
 * Accounts in the MySQL table USERS.
 *
 * <p>Every query uses parameters (the {@code ?} marks), never text glued
 * together, so input from a request cannot change the SQL.
 */
public class JdbcUserRepository implements UserRepository {

    private static final String COLUMNS = "id, username, email, password_hash, role, created_at";

    private final Database database;

    public JdbcUserRepository(Database database) {
        this.database = database;
    }

    @Override
    public Optional<User> findByUsername(String username) {
        return findOne("SELECT " + COLUMNS + " FROM users WHERE username = ?", username);
    }

    @Override
    public Optional<User> findById(int id) {
        return findOne("SELECT " + COLUMNS + " FROM users WHERE id = ?", id);
    }

    @Override
    public boolean existsByUsernameOrEmail(String username, String email) {
        String sql = "SELECT 1 FROM users WHERE username = ? OR email = ? LIMIT 1";
        try (Connection connection = database.open(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, username);
            statement.setString(2, email);
            try (ResultSet rows = statement.executeQuery()) {
                return rows.next();
            }
        } catch (SQLException e) {
            throw new DataAccessException("Could not check for an existing user", e);
        }
    }

    @Override
    public User save(String username, String email, String passwordHash, Role role) {
        String sql = "INSERT INTO users (username, email, password_hash, role) VALUES (?, ?, ?, ?)";
        try (Connection connection = database.open();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            statement.setString(1, username);
            statement.setString(2, email);
            statement.setString(3, passwordHash);
            statement.setString(4, role.name());
            statement.executeUpdate();
            try (ResultSet keys = statement.getGeneratedKeys()) {
                keys.next();
                int id = keys.getInt(1);
                return findById(id).orElseThrow();
            }
        } catch (SQLIntegrityConstraintViolationException e) {
            // Two people registered the same name at the same moment: the UNIQUE constraint caught it.
            throw new ConflictException("Username or email already in use");
        } catch (SQLException e) {
            throw new DataAccessException("Could not save the user", e);
        }
    }

    private Optional<User> findOne(String sql, Object parameter) {
        try (Connection connection = database.open(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setObject(1, parameter);
            try (ResultSet rows = statement.executeQuery()) {
                if (!rows.next()) {
                    return Optional.empty();
                }
                return Optional.of(new User(
                        rows.getInt("id"),
                        rows.getString("username"),
                        rows.getString("email"),
                        rows.getString("password_hash"),
                        Role.valueOf(rows.getString("role")),
                        rows.getTimestamp("created_at").toLocalDateTime()));
            }
        } catch (SQLException e) {
            throw new DataAccessException("Could not read the user", e);
        }
    }
}
