# Engineering rules

How the code of this project is written, so that it stays easy to change and behaves well when something goes wrong. Every service and both apps follow these rules.

## 1. Document as you build

A change is not done until its documentation is done. In the **same commit** as the code:

| What changed | What is updated with it |
|---|---|
| A class or file is added, renamed, or removed | The class diagram (draw.io source and exported image) and the file map in [class-diagrams.md](class-diagrams.md) |
| An endpoint or its JSON changes | [api-design.md](api-design.md) |
| A table, column, or document field changes | [database-design.md](database-design.md), the ER diagram, and `database/` |
| A design decision is made or reversed | The decisions table in [architecture.md](architecture.md) |
| A problem cost real time | A new entry in the [problem log](../03-problems/problem-log.md) |
| Anything a user would notice | [CHANGELOG.md](../../CHANGELOG.md) |

In the code itself:

- Every class and every public method has a short comment saying **what it is for**, not how it works line by line.
- A comment explains **why** when the reason is not obvious from the code (a rule from the PRD, a workaround, a trade-off).
- Names say what things are. No abbreviations that need explaining.

## 2. Structure: the same layers everywhere

Each service is split into layers. A layer only talks to the one below it.

| Layer | Does | Must not |
|---|---|---|
| **Routes / handlers** | Read the request, check the session and role, call the service, turn the result into JSON | Contain business rules or touch the database |
| **Services** | The rules: prices, renting, what is allowed | Know about HTTP or SQL |
| **Repositories** | Read and write the database | Contain rules |
| **Models** | Plain data | Do anything |

The apps have the matching split: **screens** (what is shown), **api** classes (calls to the services), **models** (data).

Why: a rule lives in exactly one place. Changing the renting price touches one file. Each layer can be tested without the others.

Other rules:

- One class, one job. If a class needs "and" to be described, it is two classes.
- No magic numbers. `RENT_RATE = 0.10` and `RENT_DAYS = 7` are named constants in one place.
- No duplication between the two apps: anything shared lives in `clients/bookstore-ui`.
- Settings (addresses, ports, passwords, keys) come from environment variables, never from the code. Secrets are never committed.

## 3. Errors

The aim: **a user always learns what happened and what to do next; a developer always learns where and why; nothing fails silently.**

### In the services

- **Validate at the edge.** A handler checks every field of a request before anything else runs. A bad request is answered with `400` and a message naming the field.
- **One error shape**, always: `{ "error": "message" }` with the right status code (see [api-design.md](api-design.md)).
- **Typed errors, mapped in one place.** The service layer raises errors that say what went wrong (`NotFound`, `Conflict`, `Forbidden`, `ValidationError`). One error handler per service turns each into its status code. Handlers do not build error responses by hand.
- **Unexpected errors** become `500` with a general message. The details go to the log, never to the client: no stack traces, no SQL, no file paths in a response.
- **Messages are for people.** "Not enough copies of Clean Code" rather than "constraint violation".
- **Nothing half-done.** An order is saved in one database transaction: all of it or none of it.
- **Other services can be down.** Every call from one service to another has a timeout. If user-service or book-service does not answer, the caller answers `503` with a clear message instead of hanging.
- **A failed email does not fail the order** (the bill file is the required part). The failure is logged.
- **Passwords and tokens are never logged.**

### In the apps

- Every call to a service is awaited inside a `try`, with a loading state before and a result after. The window never freezes (N2) and never shows a raw error.
- The `ApiClient` turns every failure into one `ApiException` with a readable message, so screens handle errors in one way.
- Errors appear next to where they happened, in a sentence, with a way forward ("Try again", "Clear search").
- A `401` anywhere sends the user back to the login screen: the session ended.
- The user's work survives a failure: if placing an order fails, the selected books are still there.
- Actions that cannot be undone ask first or offer Undo.
- A button is disabled while its request runs, so nothing is sent twice.

## 4. Tests

- Rules get unit tests: prices, renting, due dates, validation, who may do what.
- Every endpoint gets at least one test for success and one for each error it can return.
- A bug fix comes with a test that fails without the fix.
- `flutter analyze` and the tests pass before every commit.

## 5. Commits

- One purpose per commit, with a message that says what and why.
- Every change is committed and pushed, so the history on GitHub shows the real order of work.
