package com.bookstore.user.repository;

import com.bookstore.user.config.Config;
import com.bookstore.user.error.DataAccessException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * Opens connections to the MySQL database.
 *
 * <p>Each repository method opens a connection, uses it, and closes it. That is
 * simple and correct for a service of this size; a connection pool can replace
 * this one class later without touching the repositories.
 */
public class Database {

    private final String url;
    private final String user;
    private final String password;

    public Database(Config config) {
        this.url = config.mysqlUrl();
        this.user = config.mysqlUser();
        this.password = config.mysqlPassword();
    }

    public Connection open() {
        try {
            return DriverManager.getConnection(url, user, password);
        } catch (SQLException e) {
            throw new DataAccessException("Cannot connect to MySQL", e);
        }
    }

    /** Fails fast at start-up if the database cannot be reached, instead of on the first login. */
    public void check() {
        try (Connection connection = open()) {
            connection.isValid(3);
        } catch (SQLException e) {
            throw new DataAccessException("Cannot connect to MySQL", e);
        }
    }
}
