package com.bookstore.user.error;

/**
 * An error that is safe to show to the caller.
 *
 * <p>It carries the HTTP status and a message written for a person. The
 * handlers never build error responses themselves: they let these exceptions
 * travel up to {@code BaseHandler}, which turns each one into
 * {@code { "error": "message" }} with the right status. Anything that is not
 * an ApiException is treated as a bug and answered with a plain 500.
 */
public class ApiException extends RuntimeException {

    private final int status;

    public ApiException(int status, String message) {
        super(message);
        this.status = status;
    }

    /** The HTTP status code to answer with. */
    public int status() {
        return status;
    }

    /** 404: there is nothing at this address. */
    public static ApiException notFound(String message) {
        return new ApiException(404, message);
    }

    /** 405: the address exists but not for this HTTP method. */
    public static ApiException methodNotAllowed(String allowed) {
        return new ApiException(405, "This address only accepts " + allowed + " requests");
    }
}
