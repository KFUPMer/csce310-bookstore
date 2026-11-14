package com.bookstore.user;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.bookstore.user.model.Role;
import com.bookstore.user.repository.InMemorySessionRepository;
import com.bookstore.user.repository.InMemoryUserRepository;
import com.bookstore.user.service.AuthService;
import com.bookstore.user.service.PasswordHasher;
import com.bookstore.user.service.TokenGenerator;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Starts the real HTTP server (on a free port, with in-memory storage) and
 * calls every endpoint the way the apps will: success and each error.
 */
class UserServerHttpTest {

    private final HttpClient client = HttpClient.newHttpClient();
    private UserServer server;
    private String base;

    @BeforeEach
    void startServer() throws Exception {
        InMemoryUserRepository users = new InMemoryUserRepository();
        PasswordHasher hasher = new PasswordHasher();
        users.save("alice", "alice@example.com", hasher.hash("correct-horse"), Role.CUSTOMER);
        users.save("boss", "boss@example.com", hasher.hash("manager-pass"), Role.MANAGER);
        server = new UserServer(0, new AuthService(users, new InMemorySessionRepository(), hasher, new TokenGenerator()));
        server.start();
        base = "http://localhost:" + server.port();
    }

    @AfterEach
    void stopServer() {
        server.stop();
    }

    // ---------------------------------------------------------------- login (FR1)

    @Test
    void loginReturnsATokenAndTheUser() throws Exception {
        HttpResponse<String> response = post("/api/auth/login", "{\"username\":\"alice\",\"password\":\"correct-horse\"}", null);

        assertEquals(200, response.statusCode());
        assertTrue(response.headers().firstValue("Content-Type").orElse("").startsWith("application/json"));
        JsonObject body = json(response);
        assertEquals(64, body.get("token").getAsString().length());
        assertEquals("alice", body.get("username").getAsString());
        assertEquals("alice@example.com", body.get("email").getAsString());
        assertEquals("CUSTOMER", body.get("role").getAsString());
        assertFalse(response.body().toLowerCase().contains("hash"), "the password hash must never be sent");
    }

    @Test
    void loginWithAWrongPasswordIs401() throws Exception {
        HttpResponse<String> response = post("/api/auth/login", "{\"username\":\"alice\",\"password\":\"nope\"}", null);
        assertError(response, 401, "Wrong username or password");
    }

    @Test
    void loginWithAMissingFieldIs400() throws Exception {
        assertError(post("/api/auth/login", "{\"username\":\"alice\"}", null), 400, "Enter your password");
        assertError(post("/api/auth/login", "{}", null), 400, "Enter your username");
    }

    @Test
    void aBodyThatIsNotJsonIs400() throws Exception {
        assertError(post("/api/auth/login", "this is not json", null), 400, "The request body is not valid JSON");
        assertError(post("/api/auth/login", "", null), 400, "The request body is empty");
    }

    // ---------------------------------------------------------------- session (FR2, N4, N5)

    @Test
    void theSessionEndpointSaysWhoTheTokenBelongsTo() throws Exception {
        String token = login("boss", "manager-pass");

        HttpResponse<String> response = get("/api/auth/session", token);

        assertEquals(200, response.statusCode());
        JsonObject body = json(response);
        assertEquals("boss", body.get("username").getAsString());
        assertEquals("MANAGER", body.get("role").getAsString());
        assertFalse(body.has("token"), "the token is only returned by login");
    }

    @Test
    void withoutATokenTheSessionEndpointIs401() throws Exception {
        assertError(get("/api/auth/session", null), 401, "You are not logged in");
        assertError(get("/api/auth/session", "made-up-token"), 401, "Your session has ended. Please log in again.");
    }

    // ---------------------------------------------------------------- logout (FR2)

    @Test
    void afterLogoutTheTokenIsRefused() throws Exception {
        String token = login("alice", "correct-horse");

        HttpResponse<String> logout = post("/api/auth/logout", "", token);
        assertEquals(200, logout.statusCode());
        assertEquals("Logged out", json(logout).get("message").getAsString());

        assertEquals(401, get("/api/auth/session", token).statusCode());
        assertEquals(401, post("/api/auth/logout", "", token).statusCode());
    }

    // ---------------------------------------------------------------- register (FR3)

    @Test
    void registeringCreatesAnAccountThatCanLogIn() throws Exception {
        HttpResponse<String> response = post("/api/users/register",
                "{\"username\":\"carol\",\"email\":\"Carol@Example.com\",\"password\":\"a-long-password\"}", null);

        assertEquals(201, response.statusCode());
        JsonObject body = json(response);
        assertEquals("carol", body.get("username").getAsString());
        assertEquals("carol@example.com", body.get("email").getAsString());
        assertEquals("CUSTOMER", body.get("role").getAsString());
        assertNotNull(login("carol", "a-long-password"));
    }

    @Test
    void registeringATakenUsernameIs409() throws Exception {
        HttpResponse<String> response = post("/api/users/register",
                "{\"username\":\"alice\",\"email\":\"new@example.com\",\"password\":\"a-long-password\"}", null);
        assertError(response, 409, "Username or email already in use");
    }

    @Test
    void registeringWithABadFieldIs400AndNamesIt() throws Exception {
        HttpResponse<String> response = post("/api/users/register",
                "{\"username\":\"dave\",\"email\":\"dave@example.com\",\"password\":\"short\"}", null);
        assertError(response, 400, "The password must be at least 8 characters long");
    }

    // ---------------------------------------------------------------- wrong address or method

    @Test
    void anUnknownAddressIs404AndAWrongMethodIs405() throws Exception {
        assertEquals(404, get("/api/auth/nothing", null).statusCode());
        assertEquals(405, get("/api/auth/login", null).statusCode());
        assertEquals(405, post("/api/auth/session", "", null).statusCode());
    }

    // ---------------------------------------------------------------- helpers

    private String login(String username, String password) throws Exception {
        HttpResponse<String> response = post("/api/auth/login", "{\"username\":\"" + username + "\",\"password\":\"" + password + "\"}", null);
        assertEquals(200, response.statusCode());
        return json(response).get("token").getAsString();
    }

    private HttpResponse<String> post(String path, String body, String token) throws Exception {
        HttpRequest.Builder request = HttpRequest.newBuilder(URI.create(base + path))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(body));
        if (token != null) {
            request.header("Authorization", "Bearer " + token);
        }
        return client.send(request.build(), HttpResponse.BodyHandlers.ofString());
    }

    private HttpResponse<String> get(String path, String token) throws Exception {
        HttpRequest.Builder request = HttpRequest.newBuilder(URI.create(base + path)).GET();
        if (token != null) {
            request.header("Authorization", "Bearer " + token);
        }
        return client.send(request.build(), HttpResponse.BodyHandlers.ofString());
    }

    private static JsonObject json(HttpResponse<String> response) {
        return JsonParser.parseString(response.body()).getAsJsonObject();
    }

    private static void assertError(HttpResponse<String> response, int status, String message) {
        assertEquals(status, response.statusCode(), response.body());
        assertEquals(message, json(response).get("error").getAsString());
    }
}
