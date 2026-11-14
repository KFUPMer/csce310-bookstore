package com.bookstore.user;

import com.bookstore.user.config.Config;
import com.bookstore.user.error.UnauthorizedException;
import com.bookstore.user.http.AuthHandler;
import com.bookstore.user.http.UserHandler;
import com.bookstore.user.model.Role;
import com.bookstore.user.repository.Database;
import com.bookstore.user.repository.InMemorySessionRepository;
import com.bookstore.user.repository.InMemoryUserRepository;
import com.bookstore.user.repository.JdbcSessionRepository;
import com.bookstore.user.repository.JdbcUserRepository;
import com.bookstore.user.repository.SessionRepository;
import com.bookstore.user.repository.UserRepository;
import com.bookstore.user.service.AuthService;
import com.bookstore.user.service.PasswordHasher;
import com.bookstore.user.service.TokenGenerator;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.logging.Logger;

/**
 * Starts user-service: builds the parts, connects them, and listens for requests.
 *
 * <p>This is the only class that knows which concrete classes are used. Every
 * other class is handed what it needs through its constructor.
 */
public class UserServer {

    private static final Logger LOG = Logger.getLogger(UserServer.class.getName());

    /**
     * One listener per loopback address. Only this machine can connect: the
     * apps and the other services run here too.
     *
     * <p>Both IPv4 (127.0.0.1) and IPv6 (::1) are served because "localhost"
     * can mean either. Listening on only one made the first request to
     * "localhost" wait about two seconds for the other to time out (P-004).
     */
    private final List<HttpServer> listeners = new ArrayList<>();

    /** Builds a server on {@code port} (0 = any free port) around the given service. */
    public UserServer(int port, AuthService auth) throws IOException {
        ExecutorService workers = Executors.newFixedThreadPool(8);
        HttpServer ipv4 = listen("127.0.0.1", port, auth, workers);
        listeners.add(ipv4);
        try {
            listeners.add(listen("::1", ipv4.getAddress().getPort(), auth, workers));
        } catch (IOException e) {
            // No IPv6 on this machine, or the port is taken there. IPv4 alone still works.
            LOG.info("Not listening on IPv6 loopback: " + e.getMessage());
        }
    }

    private static HttpServer listen(String address, int port, AuthService auth, ExecutorService workers) throws IOException {
        HttpServer server = HttpServer.create(new InetSocketAddress(InetAddress.getByName(address), port), 0);
        server.createContext(AuthHandler.PATH, new AuthHandler(auth));
        server.createContext(UserHandler.PATH, new UserHandler(auth));
        server.setExecutor(workers);
        return server;
    }

    public void start() {
        listeners.forEach(HttpServer::start);
    }

    public void stop() {
        listeners.forEach(listener -> listener.stop(0));
    }

    /** The port actually in use (useful when the server was created with port 0). */
    public int port() {
        return listeners.get(0).getAddress().getPort();
    }

    /**
     * Practises the slow paths once before the first real request: password
     * hashing, and one login for a user that does not exist (which runs a
     * database query and a password check, and changes nothing). Without it
     * the first login after start-up took about 500 ms; N1 allows 500 (P-005).
     */
    private static void warmUp(PasswordHasher hasher, AuthService auth) {
        hasher.warmUp();
        try {
            auth.login("warm-up-no-such-user", "warm-up");
        } catch (UnauthorizedException expected) {
            // Exactly what should happen: there is no such user.
        }
    }

    /**
     * Sends the running server one real request (a login that is refused), so
     * that the HTTP and JSON code has also run once before a user arrives.
     * If it fails, the service still works; only the first request is slower.
     */
    private static void warmUpOverHttp(int port) {
        try {
            HttpRequest request = HttpRequest.newBuilder(URI.create("http://127.0.0.1:" + port + AuthHandler.PATH + "/login"))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString("{\"username\":\"warm-up-no-such-user\",\"password\":\"warm-up\"}"))
                    .build();
            HttpClient.newHttpClient().send(request, HttpResponse.BodyHandlers.discarding());
        } catch (IOException | RuntimeException e) {
            LOG.fine("Warm-up request failed: " + e.getMessage());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    public static void main(String[] args) throws IOException {
        Config config = Config.load();
        PasswordHasher hasher = new PasswordHasher();

        UserRepository users;
        SessionRepository sessions;
        if (config.usesMemory()) {
            users = new InMemoryUserRepository();
            sessions = new InMemorySessionRepository();
            // Memory mode starts empty, so give it the two test accounts of database/seed.py.
            users.save("customer1", "customer1@example.com", hasher.hash("customer123"), Role.CUSTOMER);
            users.save("manager1", "manager1@example.com", hasher.hash("manager123"), Role.MANAGER);
            LOG.warning("Running in MEMORY mode: no database, test accounts only, nothing is kept after a restart");
        } else {
            Database database = new Database(config);
            Runtime.getRuntime().addShutdownHook(new Thread(database::close));
            users = new JdbcUserRepository(database);
            sessions = new JdbcSessionRepository(database);
        }

        AuthService auth = new AuthService(users, sessions, hasher, new TokenGenerator());
        warmUp(hasher, auth);
        UserServer server = new UserServer(config.port(), auth);
        server.start();
        warmUpOverHttp(server.port());
        LOG.info("user-service is listening on http://localhost:" + server.port());
    }
}
