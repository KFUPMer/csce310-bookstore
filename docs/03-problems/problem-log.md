# Problem log

Every problem that cost real time or changed a decision gets an entry here. The goal is to show how the project actually went, not only the result.

## How to add an entry

Copy the template, give it the next number, and link the GitHub issue and the commit or patch version that fixed it.

```markdown
## P-000 — Short title

- **Date found:** YYYY-MM-DD
- **Phase / milestone:** e.g. M3 Backend
- **Issue:** #number
- **Status:** Open | Solved | Worked around

**What happened**
What we saw, and what we expected instead.

**Cause**
What was actually wrong (once known).

**What we tried**
1. First attempt — result
2. Second attempt — result

**Solution**
What fixed it. Fixed in version vX.Y.Z (commit abc1234).

**Lesson**
What we do differently from now on.
```

---

## Entries

## P-001 — Backend designed on the wrong technology

- **Date found:** 2026-11-13
- **Phase / milestone:** M1 Idea & Requirements
- **Issue:** —
- **Status:** Solved

**What happened**
The first design used Spring Boot (Java) for all three backend services. It was written from the PRD's introduction, which says the services are "built with Java or Python Flask", before section 4 (non-functional requirements) had been read.

**Cause**
Section 4.1 fixes the technology of each service: user services in Java HttpServer, book services in Python Flask, order and billing services in Python Flask. Spring Boot is not one of the options, and two of the three services cannot be Java at all.

**What we tried**
1. Checked whether "Java everywhere" could still satisfy the PRD — it cannot; 4.1 is explicit per service.

**Solution**
Changed the stack in every document and in the architecture diagram: user-service → Java HttpServer, book-service and order-service → Python Flask, clients stay JavaFX (which also earns +2%). `catalog-service` was renamed `book-service` to match the PRD's wording. No code existed yet, so nothing had to be rewritten.

**Lesson**
Read the whole requirements document, including the non-functional part, before choosing technology. Caught in M1, this cost one documentation update; caught in M3 it would have cost a rewrite of the backend.

## P-002 — First Flutter build blocked by Windows security

- **Date found:** 2026-11-13
- **Phase / milestone:** M4 Desktop Clients (setup, done early)
- **Issue:** #18
- **Status:** Solved

**What happened**
The first `flutter build windows` of customer-app failed with "An Application Control policy or security policy has blocked execution". The blocked program was `impellerc.exe`, the shader compiler inside the Flutter SDK that had just been downloaded.

**Cause**
Windows checks a newly downloaded program the first time it runs and can block that first run. It was not a problem in the project: the starter app had not been changed.

**What we tried**
1. Built management-app straight after: it succeeded, using the same tool.
2. Built customer-app again: it succeeded.

**Solution**
Run the build again. No security setting was changed.

**Lesson**
On a freshly installed toolchain, a first-run failure that mentions a security policy is worth one retry before looking for a fault in the code.

## P-003 — MongoDB shell blocked by Windows security

- **Date found:** 2026-11-13
- **Phase / milestone:** M3 Backend Services (setup)
- **Issue:** #7
- **Status:** Worked around

**What happened**
After installing MongoDB Shell, running `mongosh` failed with "An Application Control policy has blocked this file". MongoDB Server itself installed and runs normally.

**Cause**
Windows **Smart App Control** is turned on on this machine. It blocks programs that are not digitally signed and that it does not recognize, and `mongosh.exe` is not signed (checked: its signature status is "NotSigned"). This is also what caused P-002. Unlike P-002, a second try did not help here.

**What we tried**
1. Ran `mongosh` after the install: blocked.
2. Checked whether the server was affected: it was not; the `MongoDB` service is running on port 27017.

**Solution**
The shell is only a convenience for looking at data by hand, so it is not needed. The seed script and the services use the Python driver (`pymongo`), which works: the 15 books were loaded and searched through it. No security setting was changed.

**Why it was not switched off**
Smart App Control can be turned off in Windows Security, but Windows does not allow turning it back on without reinstalling Windows. That is too high a price for an optional tool.

**Lesson**
Depend on as few tools as possible. The project needs the database server and a driver; a separate shell is optional, and MongoDB Compass (a graphical viewer) is an alternative if looking at the data by hand becomes necessary.

## P-004 — First request to user-service took over 2 seconds

- **Date found:** 2026-11-13
- **Phase / milestone:** M3 Backend Services
- **Issue:** #8
- **Status:** Solved

**What happened**
All tests passed, but when the packaged service was started and called for real, the first login took about 2,500 ms. Requirement N1 allows 500 ms. Later requests took under 100 ms.

**Cause**
The server was listening on `127.0.0.1` (IPv4) only. The name `localhost` can also mean `::1` (IPv6), and Windows tries IPv6 first. The client waited about two seconds for that attempt to fail before trying IPv4. The tests did not show it because Java's own client goes straight to IPv4.

**What we tried**
1. Timed the same request by address: `127.0.0.1` took 95 ms, `localhost` took 2,126 ms. That confirmed the cause.
2. Considered telling every client to use `127.0.0.1`: it works, but it is a trap for anyone who types `localhost`.

**Solution**
The server now listens on both `127.0.0.1` and `::1` (two listeners sharing the same handlers). After the fix: `localhost` 58–135 ms, `127.0.0.1` 58 ms, `::1` 57 ms. The service is still not reachable from other machines.

**Lesson**
Passing tests are not the same as working. Start the real program and call it the way a client will, and measure. The Flask services must listen on both addresses too.
