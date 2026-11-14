package com.bookstore.user.error;

/** 401: the caller is not logged in, the session has ended, or the login details are wrong. */
public class UnauthorizedException extends ApiException {
    public UnauthorizedException(String message) {
        super(401, message);
    }
}
