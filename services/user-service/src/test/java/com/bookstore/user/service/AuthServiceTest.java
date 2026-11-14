package com.bookstore.user.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.bookstore.user.error.ConflictException;
import com.bookstore.user.error.UnauthorizedException;
import com.bookstore.user.model.Role;
import com.bookstore.user.model.User;
import com.bookstore.user.repository.InMemorySessionRepository;
import com.bookstore.user.repository.InMemoryUserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** The rules of login, logout, sessions, and registration, tested without HTTP or a database. */
class AuthServiceTest {

    private InMemoryUserRepository users;
    private AuthService auth;

    @BeforeEach
    void setUp() {
        users = new InMemoryUserRepository();
        PasswordHasher hasher = new PasswordHasher();
        auth = new AuthService(users, new InMemorySessionRepository(), hasher, new TokenGenerator());
        users.save("alice", "alice@example.com", hasher.hash("correct-horse"), Role.CUSTOMER);
        users.save("boss", "boss@example.com", hasher.hash("manager-pass"), Role.MANAGER);
    }

    @Test
    void loginWithTheRightPasswordStartsASession() {
        AuthService.Login login = auth.login("alice", "correct-horse");

        assertEquals("alice", login.user().username());
        assertEquals(64, login.session().token().length());
        assertEquals("alice", auth.checkSession(login.session().token()).username());
    }

    @Test
    void loginWithTheWrongPasswordIsRefused() {
        UnauthorizedException error = assertThrows(UnauthorizedException.class, () -> auth.login("alice", "wrong"));
        assertEquals("Wrong username or password", error.getMessage());
    }

    @Test
    void anUnknownUserGetsTheSameMessageAsAWrongPassword() {
        UnauthorizedException error = assertThrows(UnauthorizedException.class, () -> auth.login("nobody", "whatever"));
        assertEquals("Wrong username or password", error.getMessage());
    }

    @Test
    void everyLoginGetsItsOwnToken() {
        String first = auth.login("alice", "correct-horse").session().token();
        String second = auth.login("alice", "correct-horse").session().token();
        assertNotEquals(first, second);
    }

    @Test
    void theSessionTellsTheRole() {
        String token = auth.login("boss", "manager-pass").session().token();
        assertEquals(Role.MANAGER, auth.checkSession(token).role());
    }

    @Test
    void afterLogoutTheTokenNoLongerWorks() {
        String token = auth.login("alice", "correct-horse").session().token();

        auth.logout(token);

        assertThrows(UnauthorizedException.class, () -> auth.checkSession(token));
        assertThrows(UnauthorizedException.class, () -> auth.logout(token));
    }

    @Test
    void aMadeUpTokenIsRefused() {
        assertThrows(UnauthorizedException.class, () -> auth.checkSession("not-a-real-token"));
    }

    @Test
    void registeringCreatesACustomerWithAHashedPassword() {
        User user = auth.register("carol", "carol@example.com", "a-long-password");

        assertEquals(Role.CUSTOMER, user.role());
        assertNotEquals("a-long-password", user.passwordHash());
        assertTrue(user.passwordHash().startsWith("$2a$"), "the stored password is a bcrypt hash");
        assertEquals("carol", auth.login("carol", "a-long-password").user().username());
    }

    @Test
    void aUsernameThatIsTakenIsRefused() {
        assertThrows(ConflictException.class, () -> auth.register("alice", "other@example.com", "a-long-password"));
    }

    @Test
    void anEmailThatIsTakenIsRefused() {
        assertThrows(ConflictException.class, () -> auth.register("alice2", "alice@example.com", "a-long-password"));
    }
}
