package com.bookstore.user.repository;

import com.bookstore.user.error.DataAccessException;
import com.bookstore.user.model.Session;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.util.Optional;

/** Sessions in the MySQL table SESSIONS. */
public class JdbcSessionRepository implements SessionRepository {

    private final Database database;

    public JdbcSessionRepository(Database database) {
        this.database = database;
    }

    @Override
    public Session create(String token, int userId) {
        String sql = "INSERT INTO sessions (token, user_id) VALUES (?, ?)";
        try (Connection connection = database.open(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, token);
            statement.setInt(2, userId);
            statement.executeUpdate();
            return new Session(token, userId, LocalDateTime.now());
        } catch (SQLException e) {
            throw new DataAccessException("Could not create the session", e);
        }
    }

    @Override
    public Optional<Session> find(String token) {
        String sql = "SELECT token, user_id, created_at FROM sessions WHERE token = ?";
        try (Connection connection = database.open(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, token);
            try (ResultSet rows = statement.executeQuery()) {
                if (!rows.next()) {
                    return Optional.empty();
                }
                return Optional.of(new Session(
                        rows.getString("token"),
                        rows.getInt("user_id"),
                        rows.getTimestamp("created_at").toLocalDateTime()));
            }
        } catch (SQLException e) {
            throw new DataAccessException("Could not read the session", e);
        }
    }

    @Override
    public boolean delete(String token) {
        String sql = "DELETE FROM sessions WHERE token = ?";
        try (Connection connection = database.open(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, token);
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new DataAccessException("Could not delete the session", e);
        }
    }
}
