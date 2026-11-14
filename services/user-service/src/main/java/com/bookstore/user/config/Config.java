package com.bookstore.user.config;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;

/**
 * The service's settings.
 *
 * <p>Read from environment variables first, then from a {@code .env} file
 * (in this folder or in {@code services/}), then defaults. Nothing secret is
 * written in the code, and {@code .env} is ignored by git.
 *
 * @param port          the port to listen on
 * @param storage       "mysql" (the real database) or "memory" (no database; for trying things out)
 * @param mysqlUrl      JDBC address of the database
 * @param mysqlUser     MySQL user name
 * @param mysqlPassword MySQL password
 */
public record Config(int port, String storage, String mysqlUrl, String mysqlUser, String mysqlPassword) {

    public static final String STORAGE_MYSQL = "mysql";
    public static final String STORAGE_MEMORY = "memory";

    public static Config load() {
        Map<String, String> file = readDotEnv();
        String host = value("MYSQL_HOST", file, "localhost");
        String database = value("MYSQL_DATABASE", file, "bookstore");
        return new Config(
                Integer.parseInt(value("USER_SERVICE_PORT", file, "8081")),
                value("STORAGE", file, STORAGE_MYSQL).toLowerCase(),
                "jdbc:mysql://" + host + ":3306/" + database,
                value("MYSQL_USER", file, "root"),
                value("MYSQL_PASSWORD", file, ""));
    }

    public boolean usesMemory() {
        return STORAGE_MEMORY.equals(storage);
    }

    private static String value(String name, Map<String, String> file, String fallback) {
        String fromEnvironment = System.getenv(name);
        if (fromEnvironment != null && !fromEnvironment.isBlank()) {
            return fromEnvironment;
        }
        String fromFile = file.get(name);
        return fromFile != null && !fromFile.isBlank() ? fromFile : fallback;
    }

    /** Reads NAME=value lines from the first .env file found. Lines starting with # are comments. */
    private static Map<String, String> readDotEnv() {
        Map<String, String> values = new HashMap<>();
        for (Path candidate : new Path[] {Path.of(".env"), Path.of("..", ".env"), Path.of("services", ".env")}) {
            if (!Files.isRegularFile(candidate)) {
                continue;
            }
            try {
                for (String line : Files.readAllLines(candidate)) {
                    String trimmed = line.trim();
                    int equals = trimmed.indexOf('=');
                    if (trimmed.isEmpty() || trimmed.startsWith("#") || equals < 1) {
                        continue;
                    }
                    values.put(trimmed.substring(0, equals).trim(), trimmed.substring(equals + 1).trim());
                }
            } catch (IOException e) {
                // An unreadable .env is not fatal: environment variables and defaults still apply.
            }
            break;
        }
        return values;
    }
}
