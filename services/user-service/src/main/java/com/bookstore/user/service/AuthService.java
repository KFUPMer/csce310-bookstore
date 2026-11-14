package com.bookstore.user.service;

import com.bookstore.user.error.ConflictException;
import com.bookstore.user.error.UnauthorizedException;
import com.bookstore.user.model.Role;
import com.bookstore.user.model.Session;
import com.bookstore.user.model.User;
import com.bookstore.user.repository.SessionRepository;
import com.bookstore.user.repository.UserRepository;

/**
 * The rules of logging in, logging out, sessions, and registering.
 *
 * <p>Knows nothing about HTTP or SQL: it is given repositories and returns
 * plain objects or throws an ApiException.
 */
public class AuthService {

    /** The result of a successful login: the new session and who it belongs to. */
    public record Login(Session session, User user) {
    }

    private static final String WRONG_LOGIN = "Wrong username or password";

    private final UserRepository users;
    private final SessionRepository sessions;
    private final PasswordHasher hasher;
    private final TokenGenerator tokens;

    /**
     * The hash of a throwaway value. When the username does not exist we still
     * run one bcrypt check against this, so that a login for an unknown user
     * takes as long as one for a known user. Otherwise the response time would
     * reveal which usernames exist.
     */
    private final String dummyHash;

    public AuthService(UserRepository users, SessionRepository sessions, PasswordHasher hasher, TokenGenerator tokens) {
        this.users = users;
        this.sessions = sessions;
        this.hasher = hasher;
        this.tokens = tokens;
        this.dummyHash = hasher.hash("not-a-real-password");
    }

    /**
     * FR1: checks the username and password and starts a session.
     *
     * @throws UnauthorizedException if the user does not exist or the password is wrong.
     *                               The message is the same in both cases on purpose.
     */
    public Login login(String username, String password) {
        User user = users.findByUsername(username).orElse(null);
        boolean correct = hasher.matches(password, user == null ? dummyHash : user.passwordHash());
        if (user == null || !correct) {
            throw new UnauthorizedException(WRONG_LOGIN);
        }
        Session session = sessions.create(tokens.newToken(), user.id());
        return new Login(session, user);
    }

    /**
     * FR2: ends the session, so the token stops working.
     *
     * @throws UnauthorizedException if the token is not a current session
     */
    public void logout(String token) {
        if (!sessions.delete(token)) {
            throw new UnauthorizedException("You are not logged in");
        }
    }

    /**
     * FR2, N4: tells who a token belongs to. The other services call this to
     * validate every request they receive.
     *
     * @throws UnauthorizedException if the token is not a current session
     */
    public User checkSession(String token) {
        Session session = sessions.find(token)
                .orElseThrow(() -> new UnauthorizedException("Your session has ended. Please log in again."));
        return users.findById(session.userId())
                .orElseThrow(() -> new UnauthorizedException("Your session has ended. Please log in again."));
    }

    /**
     * FR3: creates a customer account. The fields are already validated by the caller.
     *
     * <p>New accounts are always customers; managers are created by the seed script.
     *
     * @throws ConflictException if the username or email is already used
     */
    public User register(String username, String email, String password) {
        if (users.existsByUsernameOrEmail(username, email)) {
            throw new ConflictException("Username or email already in use");
        }
        return users.save(username, email, hasher.hash(password), Role.CUSTOMER);
    }
}
