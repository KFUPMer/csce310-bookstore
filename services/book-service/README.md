# book-service

Search books, and add and update them. Python Flask and MongoDB. Requirements: FR4, FR5, FR6, FR14, N4, N5.

## Run

```bash
pip install -r requirements.txt
```

```bash
python -m book_service
```

Needs MongoDB and user-service running. Listens on port 8082, on this machine only.

## Test

```bash
python -m unittest discover -s tests -t .
```

## Status (2026-11-13): work in progress

- Code written in four layers (routes, services, repository, models).
- 31 tests pass: 24 on the endpoints, 7 against real MongoDB.
- Run for real together with user-service: search, login checks, role checks, and the "login service is down" case (503) all answered correctly, in 15 to 60 ms.
- **Not yet verified on the running service:** adding a book, updating a book, and the copies endpoint. The manual check of those failed because of a quoting mistake in the test script, not a known fault in the service. The automated tests for them pass.
- **Still to do:** class diagram, file map, entries in the logs and in REFERENCES.md (new dependency: waitress, ZPL 2.1).
