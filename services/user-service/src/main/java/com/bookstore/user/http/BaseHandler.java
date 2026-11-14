package com.bookstore.user.http;

import com.bookstore.user.error.ApiException;
import com.bookstore.user.error.UnauthorizedException;
import com.bookstore.user.error.ValidationException;
import com.google.gson.JsonParseException;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * What every handler has in common: reading the request, writing JSON, and
 * above all turning errors into responses in ONE place.
 *
 * <p>Subclasses implement {@link #route} and simply throw when something is
 * wrong. This class guarantees that a caller always gets
 * {@code { "error": "message" }} with a sensible status, and that an
 * unexpected failure is logged in full but answered without any details.
 */
public abstract class BaseHandler implements HttpHandler {

    private static final Logger LOG = Logger.getLogger(BaseHandler.class.getName());

    /** A request body larger than this is refused. Ours are a few dozen bytes. */
    private static final int MAX_BODY_BYTES = 16 * 1024;

    private static final String BEARER = "Bearer ";

    /** Handles one request. Throw an {@link ApiException} to answer with an error. */
    protected abstract void route(HttpExchange exchange) throws IOException;

    @Override
    public final void handle(HttpExchange exchange) throws IOException {
        try {
            route(exchange);
        } catch (ApiException e) {
            sendError(exchange, e.status(), e.getMessage());
        } catch (JsonParseException e) {
            sendError(exchange, 400, "The request body is not valid JSON");
        } catch (Exception e) {
            // A bug or a failed database. Full details go to the log, none to the caller.
            LOG.log(Level.SEVERE, exchange.getRequestMethod() + " " + exchange.getRequestURI().getPath() + " failed", e);
            sendError(exchange, 500, "Something went wrong on the server. Please try again.");
        } finally {
            exchange.close();
        }
    }

    /** @throws ApiException 405 if the request uses a different HTTP method */
    protected void requireMethod(HttpExchange exchange, String method) {
        if (!method.equalsIgnoreCase(exchange.getRequestMethod())) {
            throw ApiException.methodNotAllowed(method);
        }
    }

    /**
     * Reads the JSON body into an object.
     *
     * @throws ValidationException if the body is empty or too large
     */
    protected <T> T readJson(HttpExchange exchange, Class<T> type) throws IOException {
        byte[] bytes;
        try (InputStream body = exchange.getRequestBody()) {
            bytes = body.readNBytes(MAX_BODY_BYTES + 1);
        }
        if (bytes.length > MAX_BODY_BYTES) {
            throw new ValidationException("The request is too large");
        }
        T value = Json.read(new String(bytes, StandardCharsets.UTF_8), type);
        if (value == null) {
            throw new ValidationException("The request body is empty");
        }
        return value;
    }

    /**
     * Reads the session token from the {@code Authorization: Bearer <token>} header (N4).
     *
     * @throws UnauthorizedException if the header is missing or malformed
     */
    protected String bearerToken(HttpExchange exchange) {
        String header = exchange.getRequestHeaders().getFirst("Authorization");
        if (header == null || !header.startsWith(BEARER) || header.length() == BEARER.length()) {
            throw new UnauthorizedException("You are not logged in");
        }
        return header.substring(BEARER.length()).trim();
    }

    protected void sendJson(HttpExchange exchange, int status, Object body) throws IOException {
        byte[] bytes = Json.write(body).getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", "application/json; charset=utf-8");
        exchange.sendResponseHeaders(status, bytes.length);
        exchange.getResponseBody().write(bytes);
    }

    private void sendError(HttpExchange exchange, int status, String message) {
        try {
            sendJson(exchange, status, Map.of("error", message));
        } catch (IOException | RuntimeException e) {
            // The caller went away, or the response had already started. Nothing more can be sent.
            LOG.log(Level.WARNING, "Could not send the error response", e);
        }
    }
}
