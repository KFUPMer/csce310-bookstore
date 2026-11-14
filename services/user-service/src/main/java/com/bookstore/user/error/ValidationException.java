package com.bookstore.user.error;

/** 400: the request is missing a field, or a value is not acceptable. The message names the field. */
public class ValidationException extends ApiException {
    public ValidationException(String message) {
        super(400, message);
    }
}
