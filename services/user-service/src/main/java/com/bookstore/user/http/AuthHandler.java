package com.bookstore.user.http;

import com.bookstore.user.error.ApiException;
import com.bookstore.user.http.dto.LoginRequest;
import com.bookstore.user.http.dto.UserResponse;
import com.bookstore.user.model.User;
import com.bookstore.user.service.AuthService;
import com.sun.net.httpserver.HttpExchange;
import java.io.IOException;
import java.util.Map;

/**
 * The endpoints under /api/auth: login, logout, and session check.
 *
 * <p>Only translates between HTTP and {@link AuthService}; the rules live there.
 */
public class AuthHandler extends BaseHandler {

    public static final String PATH = "/api/auth";

    private final AuthService auth;

    public AuthHandler(AuthService auth) {
        this.auth = auth;
    }

    @Override
    protected void route(HttpExchange exchange) throws IOException {
        switch (exchange.getRequestURI().getPath()) {
            case PATH + "/login" -> login(exchange);
            case PATH + "/logout" -> logout(exchange);
            case PATH + "/session" -> session(exchange);
            default -> throw ApiException.notFound("There is nothing at this address");
        }
    }

    /** POST /api/auth/login (FR1). */
    private void login(HttpExchange exchange) throws IOException {
        requireMethod(exchange, "POST");
        LoginRequest request = readJson(exchange, LoginRequest.class);
        request.validate();
        AuthService.Login login = auth.login(request.username().trim(), request.password());
        sendJson(exchange, 200, UserResponse.withToken(login.user(), login.session().token()));
    }

    /** POST /api/auth/logout (FR2). */
    private void logout(HttpExchange exchange) throws IOException {
        requireMethod(exchange, "POST");
        auth.logout(bearerToken(exchange));
        sendJson(exchange, 200, Map.of("message", "Logged out"));
    }

    /** GET /api/auth/session (FR2, N4, N5). Called by the other services to validate a token. */
    private void session(HttpExchange exchange) throws IOException {
        requireMethod(exchange, "GET");
        User user = auth.checkSession(bearerToken(exchange));
        sendJson(exchange, 200, UserResponse.of(user));
    }
}
