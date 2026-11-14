package com.bookstore.user.error;

/** 409: the request is valid but clashes with what already exists, e.g. a username that is taken. */
public class ConflictException extends ApiException {
    public ConflictException(String message) {
        super(409, message);
    }
}
