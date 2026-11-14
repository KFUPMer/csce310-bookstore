package com.bookstore.user.error;

/**
 * The database could not be reached or a query failed.
 *
 * <p>Deliberately NOT an {@link ApiException}: the cause may contain SQL or
 * connection details, which must not be sent to a client. BaseHandler logs it
 * and answers with a general 500.
 */
public class DataAccessException extends RuntimeException {
    public DataAccessException(String message, Throwable cause) {
        super(message, cause);
    }
}
