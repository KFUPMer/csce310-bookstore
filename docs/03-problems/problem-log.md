# Problem log

Every problem that cost real time or changed a decision gets an entry here. The goal is to show how the project actually went, not only the result.

Much of this project was built with an AI coding assistant (Claude). Its mistakes and dead ends are logged here like anyone else's, marked **Who: assistant**. Improvements that go beyond the requirements are in the [enhancement log](enhancement-log.md).

## Index

| ID | Problem | Who | Status |
|---|---|---|---|
| P-001 | Backend designed on the wrong technology | Assistant | Solved |
| P-002 | First Flutter build blocked by Windows security | Environment | Solved |
| P-003 | MongoDB shell blocked by Windows security | Environment | Worked around |
| P-004 | First request to user-service took over 2 seconds | Assistant | Solved |
| P-005 | Login too close to the 500 ms limit against the real database | Assistant | Solved |
| P-006 | Requirements and deadlines were guessed before the PRD arrived | Assistant | Solved |
| P-007 | Bundled fonts did not appear in the app | Assistant | Solved |
| P-008 | A documentation update failed and a commit silently did not happen | Assistant | Solved |
| P-009 | A hand-written placeholder was used where a real bcrypt hash was needed | Assistant | Solved before it ran |
| P-010 | The requested typeface (SF Pro) could not be used | Licensing | Worked around |
| P-011 | Diagram layout faults, and deleted diagrams coming back | Assistant | Solved |
| P-012 | Maven was not available from the package manager | Environment | Solved |
| P-013 | Small things that went wrong | Mixed | Solved |
| P-014 | A manual check failed and left a service running | Assistant | Solved |

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

## P-005 — Login too close to the 500 ms limit against the real database

- **Date found:** 2026-11-13
- **Phase / milestone:** M3 Backend Services
- **Issue:** #8
- **Status:** Solved

**What happened**
In memory mode every request took under 150 ms. Against the real MySQL database, logins took 290–375 ms and the first login after start-up took 539 ms. N1 allows 500 ms. Session checks, which the other two services will make on every request, took about 75 ms.

**Cause**
Three separate things, found one at a time by measuring:

1. The Python seed script hashed passwords with bcrypt cost 12; the Java service uses cost 10. Cost 12 is four times slower to check.
2. Every query opened a new database connection (about 35 ms each), and a login needs two queries.
3. Java runs code slowly the first few times. The first request paid for that in the hashing, database, HTTP, and JSON code all at once.

**What we tried**
1. Seed script changed to cost 10: logins dropped to about 200 ms, first login still 539 ms.
2. Connection pool (HikariCP): session checks dropped from about 75 ms to 7–19 ms, first login 509 ms.
3. Practice hashing at start-up: first login 430–470 ms. Under the limit, but too close.
4. A practice login against the database at start-up: first login 258–495 ms. Better on average, still not reliable.
5. One real request from the service to itself at start-up: first login 102–255 ms over four cold starts.

**Solution**
All of the above together: the same bcrypt cost on both sides, a connection pool, and a warm-up at start-up (`PasswordHasher.warmUp`, `UserServer.warmUp`, `UserServer.warmUpOverHttp`). The warm-up logs in as a user that does not exist, so it changes nothing.

**Lesson**
Test against the real database, not only the in-memory one, and measure from a cold start, because that is what a demo is. A number that passes with no margin is not a pass. Each fix was measured before the next was tried, which showed that no single change was enough.

## P-006 — Requirements and deadlines were guessed before the PRD arrived

- **Date found:** 2026-11-13
- **Phase / milestone:** M1 Idea & Requirements
- **Who:** assistant
- **Status:** Solved

**What happened**
The repository was set up from a two-line description of the project. To fill it, the assistant invented a set of requirements (categories, reviews, order history, shipping statuses, a "staff" role, login by email) and a five-week schedule. When the PRD arrived it contradicted most of them.

**Cause**
Starting the design before having the requirements document, and writing guesses in the same confident form as facts.

**Solution**
Everything was rewritten from the PRD (FR1–FR14, then N1–N5), the invented features were removed and listed as removed, and the schedule was redone for the real deadline of 4 December. P-001 is the largest single consequence of this.

**Lesson**
Ask for the requirements document first. When something has to be assumed, label it as an assumption where it is written, which the early drafts did ("proposed"), and keep assumptions out of anything that looks final, such as GitHub milestones with dates.

## P-007 — Bundled fonts did not appear in the app

- **Date found:** 2026-11-13
- **Phase / milestone:** M2 Design (style preview)
- **Who:** assistant
- **Status:** Solved

**What happened**
After Inter and Source Serif 4 were added to the shared package, the app was rebuilt and screenshots were taken. The build succeeded and the analyzer reported no issues, but the screenshots still showed the Windows system font: headings that should have been serif were not.

**Cause**
The build had reused earlier output and did not pick up the new font declarations in the package's `pubspec.yaml`. The built app's font list (`FontManifest.json`) did not contain the new fonts.

**What we tried**
1. Looked at the screenshots rather than trusting the successful build: the fonts were visibly wrong.
2. Opened the built app's font list: the fonts were missing from it.
3. Cleaned the build and rebuilt: the fonts appeared.

**Solution**
`flutter clean`, then rebuild. The font list was checked again before taking new screenshots.

**Lesson**
"It compiled" does not mean "it worked". A change to assets or fonts needs a clean build, and visual work has to be checked by looking at it.

## P-008 — A documentation update failed and a commit silently did not happen

- **Date found:** 2026-11-13
- **Phase / milestone:** M3 Backend Services
- **Who:** assistant
- **Status:** Solved

**What happened**
The documents are updated by small scripts and then committed in one command. One script crashed half-way (a Windows path containing a backslash was treated as an escape sequence in a text replacement). Because the commit was chained after the script, nothing was committed or pushed, and the summary for that step had already been written as if it had been.

**Cause**
A script error in the middle of a chain of commands, and a summary prepared before reading the output.

**Solution**
The output was read before anything was reported, the script was fixed to treat replacement text literally, and it was rerun. The commit and push were then checked. Earlier, a similar failure came from a quotation mark inside a command; since then, longer scripts are written to a file and run from there instead of being typed inline.

**Lesson**
Read the result of every step before describing it. Chain a commit after the work so that a failure stops the commit (which is what happened here and is why nothing half-done was pushed). Never report from the plan; report from the output.

## P-009 — A hand-written placeholder was used where a real bcrypt hash was needed

- **Date found:** 2026-11-13
- **Phase / milestone:** M3 Backend Services
- **Who:** assistant
- **Status:** Solved before it ran

**What happened**
To make a login for an unknown user take as long as one for a known user (E-013), the service compares the password against a spare hash. The first version of `AuthService` contained that spare hash as a constant typed by hand to look like a bcrypt hash.

**Cause**
Writing something that looks right instead of producing something that is right. A made-up string is very unlikely to be a valid bcrypt hash; the library would have rejected it immediately, the timing protection would silently not have worked, and nothing would have reported it.

**Solution**
Caught on re-reading, before the code was compiled. The constant was removed and the spare hash is now computed by the real hasher when the service starts.

**Lesson**
Never invent a value that has a format: compute it. And a protection that fails silently needs a test; the test `anUnknownUserGetsTheSameMessageAsAWrongPassword` covers the message, though not yet the timing.

## P-010 — The requested typeface (SF Pro) could not be used

- **Date found:** 2026-11-13
- **Phase / milestone:** M2 Design
- **Who:** licensing
- **Status:** Worked around

**What happened**
The project owner asked for Apple's SF Pro, to get an Apple-like interface.

**Cause**
Apple licenses SF Pro only for software that runs on Apple platforms. These are Windows apps, so bundling it is not allowed.

**Solution**
Inter was used for interface text and Source Serif 4 for headings. Both are open source under the SIL Open Font License, which allows bundling, and both were taken from their official GitHub repositories with their license files.

**Lesson**
Check the license of an asset before designing around it.

## P-011 — Diagram layout faults, and deleted diagrams coming back

- **Date found:** 2026-11-13 (repeatedly)
- **Phase / milestone:** M2 Design, M3 Backend Services
- **Who:** assistant
- **Status:** Solved

**What happened**
The diagrams are generated by scripts and exported to images. Many first exports had faults: lines drawn through boxes (class diagrams, use case, composite structure, the user-service diagram), text cut off or overflowing (method names, wireframe labels, activity decisions, cover titles breaking in the middle of a word), labels hidden under other labels (component diagram), a placeholder `<orderId>` that vanished because it was read as HTML, and titles that were not centered.

Separately, after the deployment, package, and composite structure diagrams were removed on request, the script that generates the other diagrams still contained them, so every later run recreated the three deleted files.

**Cause**
Positions are calculated, not seen, so a layout can be wrong in ways only visible in the image. And the removed diagrams were deleted from the repository but not from the generator.

**Solution**
Every exported image is opened and looked at before it is committed; each fault above was fixed and the image exported again. The recreated files are deleted after each run, and the list of changed files is checked before committing so that only the intended diagrams change.

**Lesson**
Generated output has to be inspected, every time. Removing something means removing it from whatever generates it, not only from where it ends up. The second half of this is still open: see "Known gaps".

## P-012 — Maven was not available from the package manager

- **Date found:** 2026-11-13
- **Phase / milestone:** M3 Backend Services (setup)
- **Who:** environment
- **Status:** Solved

**What happened**
Java and MongoDB were installed with `winget`. Maven is not in the winget catalog.

**Solution**
Maven 3.9.9 was downloaded from Apache's own archive, its SHA-512 checksum was compared with the one Apache publishes before unpacking it, and its `bin` folder was added to the user PATH.

**Lesson**
When a tool has to come from a direct download, take it from the publisher and verify the checksum.

## P-013 — Small things that went wrong

Problems that cost minutes, not hours. Listed so the record is complete.

| What happened | Who | What was done |
|---|---|---|
| The project folder could not be renamed from `csce310-bookstore` to `CSCE310-Bookstore`: Windows treats names that differ only in capital letters as the same | Environment | Kept the lower-case name |
| The Mermaid diagrams in the first docs had to be replaced when the owner asked for draw.io | Assistant | Redrawn in draw.io; draw.io Desktop installed for exporting |
| The first headless screenshot of the sample bill produced no file | Assistant | Run a different way (a separate browser profile and waiting for it to finish) |
| The sequence diagram was drawn in color; the owner wanted it plain | Assistant | Redrawn without color |
| In the catalog preview, price and availability overlapped on narrow cards, and "Only 2 left" was cut off | Assistant | Shorter wording on cards; found by looking at the screenshots |
| The detail panel's "Rent" button was cut off at the default window height | Assistant | The panel now scrolls when the window is short |
| The login response sent `"token": null` on endpoints that have no token | Assistant | Empty fields are no longer sent; a test checks it |
| The first timing check of the service reported "server not up" although it was | Assistant | The check itself was hitting the `localhost` delay that became P-004 |
| The screen class was named `CatalogScreen` in code but `SearchScreen` in the approved class diagram | Assistant | Code renamed to match the diagram |
| The use case diagram was missing the mail server as an actor | Assistant | Added after the owner questioned the actors |

## P-014 — A manual check failed and left a service running

- **Date found:** 2026-11-13, finished 2026-11-16
- **Phase / milestone:** M3 Backend Services
- **Who:** assistant
- **Status:** Solved

**What happened**
After book-service passed its tests, it was started together with user-service and called by hand from a PowerShell script. The first run printed nothing useful and ended with errors. The second run showed search and the login checks working, but "manager adds a book" failed with no response at all, which made the three checks after it meaningless. And after the first run, book-service was still running in the background.

**Cause**
Two mistakes in the checking script, none in the service:

1. PowerShell does not distinguish capital letters in variable names. The script kept the service's process in `$b` and the address in `$B`; the second overwrote the first, so the script could no longer stop the service it had started.
2. The test book's title had spaces in it ("Run Check Book"). The way the script passed it to the command split it into pieces, so the request was never sent.

**What we tried**
1. Found and stopped the leftover process, and added a check at the end of every run that no service process is left.
2. Renamed the variables: this fixed the first mistake and exposed the second.

**Solution**
The manual check was rewritten in Python, which sends requests directly instead of building a command line. Each check now states the result it expects and the script says plainly whether all passed. All 16 checks passed, in 3 to 38 ms. The work was committed in between as "work in progress", with the three unverified endpoints named as unverified.

**Lesson**
Write checks in a language that handles data properly rather than gluing text into commands. A check must say what it expects, so that a failure cannot be mistaken for a pass. Anything a script starts, it must be sure to stop. And when a check fails, say what was and was not verified instead of rounding up.

## Known gaps

Things that are known to be unfinished or unverified, so nobody is surprised later.

| Gap | Since | Plan |
|---|---|---|
| The scripts that generate the diagrams are not in the repository, only their output | M2 | Clean them up (remove the three deleted diagrams from them) and add them under `tools/` |
| How the app's animations and scrolling feel has not been judged by a person | M2 | The owner tries the preview; adjust in M4 |
| Trackpad scrolling, screen readers, and a color-blindness simulation are untested | M2 | Test during M5 |
| The timing protection of E-013 has a test for the message but not for the timing | M3 | Add a timing test, or accept and document |
| Sessions never expire; they end only at logout | M2 | The PRD asks for exactly this (FR2). Noted in case an expiry is wanted |
| order-service is not built | M3 | Next |
