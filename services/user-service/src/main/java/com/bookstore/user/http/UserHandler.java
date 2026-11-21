package com.bookstore.user.http;

import com.bookstore.user.error.ApiException;
import com.bookstore.user.http.dto.RegisterRequest;
import com.bookstore.user.http.dto.UserResponse;
import com.bookstore.user.model.User;
import com.bookstore.user.service.AuthService;
import com.sun.net.httpserver.HttpExchange;
import java.io.IOException;
import java.util.Locale;

/** The endpoints under /api/users: registration (FR3). */
public class UserHandler extends BaseHandler {

    public static final String PATH = "/api/users";

    private final AuthService auth;

    public UserHandler(AuthService auth) {
        this.auth = auth;
    }

    @Override
    protected void route(HttpExchange exchange) throws IOException {
        if ((PATH + "/register").equals(exchange.getRequestURI().getPath())) {
            register(exchange);
        } else {
            throw ApiException.notFound("There is nothing at this address");
        }
    }

    /** POST /api/users/register. */
    private void register(HttpExchange exchange) throws IOException {
        requireMethod(exchange, "POST");
        RegisterRequest request = readJson(exchange, RegisterRequest.class);
        request.validate();
        // Locale.ROOT: the same result on every computer. With a Turkish locale "I" would become a dotless "ı" (P-023).
        User user = auth.register(request.username(), request.email().trim().toLowerCase(Locale.ROOT), request.password());
        sendJson(exchange, 201, UserResponse.of(user));
    }
}
