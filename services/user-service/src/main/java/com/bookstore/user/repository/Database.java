package com.bookstore.user.repository;

import com.bookstore.user.config.Config;
import com.bookstore.user.error.DataAccessException;
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import java.sql.Connection;
import java.sql.SQLException;

/**
 * Hands out connections to the MySQL database from a small pool.
 *
 * <p>Opening a connection costs tens of milliseconds, and a login needs two
 * queries. Opening one per query made the first login slower than the 500 ms
 * that N1 allows (P-005). The pool opens a few connections once and lends
 * them out: {@code close()} on a borrowed connection returns it to the pool.
 *
 * <p>This is the only class that knows a pool exists; the repositories just
 * ask for a connection and close it.
 */
public class Database implements AutoCloseable {

    /** Enough for the service's 8 worker threads, which each use one connection briefly. */
    private static final int POOL_SIZE = 8;

    /** How long a request waits for a free connection before failing, in milliseconds. */
    private static final long WAIT_FOR_CONNECTION_MS = 3_000;

    private final HikariDataSource pool;

    /**
     * Connects to MySQL. Fails here, at start-up, if the database cannot be
     * reached, rather than on the first login.
     *
     * @throws DataAccessException if the database cannot be reached
     */
    public Database(Config config) {
        HikariConfig settings = new HikariConfig();
        settings.setJdbcUrl(config.mysqlUrl());
        settings.setUsername(config.mysqlUser());
        settings.setPassword(config.mysqlPassword());
        settings.setMaximumPoolSize(POOL_SIZE);
        settings.setMinimumIdle(2);
        settings.setConnectionTimeout(WAIT_FOR_CONNECTION_MS);
        settings.setPoolName("user-service");
        try {
            this.pool = new HikariDataSource(settings);
        } catch (RuntimeException e) {
            throw new DataAccessException("Cannot connect to MySQL. Check that it is running and that services/.env has the right settings.", e);
        }
    }

    /** Borrows a connection. Always use it in try-with-resources so it goes back to the pool. */
    public Connection open() {
        try {
            return pool.getConnection();
        } catch (SQLException e) {
            throw new DataAccessException("Could not get a database connection", e);
        }
    }

    /** Closes every connection. Called when the service stops. */
    @Override
    public void close() {
        pool.close();
    }
}
