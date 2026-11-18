# user-service

Login, logout, sessions, and registration. Java 21, the JDK's built-in `HttpServer`, MySQL.

Requirements covered: FR1, FR2, FR3, FR11, N3, N4, N5.

## Endpoints

| Method | Path | Does |
|---|---|---|
| POST | `/api/auth/login` | Checks username and password, returns a session token |
| POST | `/api/auth/logout` | Ends the session |
| GET | `/api/auth/session` | Says who a token belongs to (used by the other services) |
| POST | `/api/users/register` | Creates a customer account |

Exact requests, responses, and errors: [api-design.md](../../docs/02-design/api-design.md).

## Build and test

```bash
mvn package
```

This compiles, runs the 26 tests, and produces `target/user-service.jar`.

## Run

**With MySQL** (the real mode). Needs the `bookstore` database (see [environment.md](../../docs/05-setup/environment.md)) and the MySQL settings in `services/.env`:

```bash
java -jar target/user-service.jar
```

**Without a database** (memory mode), for trying the service or building the apps against it. It starts with the two test accounts of `database/seed.py`, and forgets everything when stopped. In Command Prompt:

```bash
set STORAGE=memory && java -jar target/user-service.jar
```

The service listens on port 8081 (change with `USER_SERVICE_PORT`), on this machine only.

## How it is built

Four layers; each only calls the one below ([engineering rules](../../docs/02-design/engineering-rules.md)):

| Package | Layer | Classes |
|---|---|---|
| `http`, `http.dto` | Receives requests, validates them, sends JSON, turns errors into responses | `BaseHandler`, `AuthHandler`, `UserHandler`, `Json`, `LoginRequest`, `RegisterRequest`, `UserResponse` |
| `service` | The rules | `AuthService`, `PasswordHasher`, `TokenGenerator` |
| `repository` | Database access | `UserRepository`, `SessionRepository`, and a MySQL and an in-memory version of each; `Database` (connection pool) |
| `model` | Plain data | `User`, `Session`, `Role` |

Plus `error` (the exceptions), `config.Config` (settings), and `UserServer` (start-up).

Class diagram and a description of every file: [class-diagrams.md](../../docs/02-design/class-diagrams.md#user-service).

## Error handling

Handlers and services throw; `BaseHandler` catches everything in one place:

| Thrown | Answer |
|---|---|
| `ValidationException` | 400, with a message naming the field |
| `UnauthorizedException` | 401 |
| `ApiException.notFound` / `methodNotAllowed` | 404 / 405 |
| `ConflictException` | 409 |
| Body is not JSON | 400 |
| Anything else (a bug, the database is down) | 500 with a general message; the details go to the log only |

## Security notes

- Passwords are stored as bcrypt hashes, never as text, and never logged or returned.
- A wrong password and an unknown username get the same message and take the same time, so the service does not reveal which usernames exist.
- Tokens are 32 random bytes from a cryptographic source.
- All SQL uses parameters, so request input cannot change a query.
- Request bodies over 16 KB are refused.

## Status

Built and verified on 2026-11-13:

- All 26 tests pass.
- Every endpoint was called on the running service **against the real MySQL database**: login with the accounts created by the Python seed script, session check, wrong password, register, duplicate register, logout, session after logout.
- Timings against MySQL, over four cold starts: login 85–255 ms (most of it is bcrypt, on purpose), session check 7–19 ms. N1 allows 500 ms.

## Performance notes

- Database connections come from a small pool (HikariCP) instead of being opened per query.
- At start-up the service practises password hashing and sends itself one refused login, so the first real request is as fast as later ones. See P-005 in the problem log.
