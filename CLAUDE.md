# CSCE310 Bookstore: notes for the AI assistant

Read this first. It is what a new session needs to carry on without the earlier conversation.

## What this is

A course project, done individually, due **2026-12-04**. An online bookstore: three backend services and two Flutter desktop apps. The repo must show the *process* (idea, design, problems, plan), not only code. The owner must be able to explain everything in it.

Requirements are in `docs/01-idea/project-idea.md` (FR1–FR14, N1–N5, from the course PRD). Every extra-credit item is being done.

## Where things stand

The live plan is `docs/04-planning/milestones.md`; tasks are GitHub issues on `KFUPMer/csce310-bookstore` (use `gh`).

| Part | State |
|---|---|
| M1 Idea, M2 Design, M3 Backend, M4 Clients | Closed. Released as v0.1.0, v0.2.0, v0.3.0, v0.4.0 |
| user-service (Java HttpServer, MySQL) | Done, verified against MySQL |
| book-service (Python Flask, MongoDB) | Done, verified on the running service |
| order-service (Python Flask, MySQL) | Done, verified on the running service with the other two. A real bill email was sent through Gmail (`email_check.py`) and the owner confirmed it looks right in the inbox. `GET /api/orders/{id}`, `GET /api/orders/mine`, `POST /api/orders/{id}/pay` added in M4 (101 tests) |
| bookstore-ui (shared) | The look, plus the shared log-in form, `ApiClient`, `Session`, `UserApi`, `BookApi`, `Book`, `Order` (18 tests) |
| customer-app (Flutter) | Built on the real services (issues 11, 15), 34 tests. The owner ran it: it works. Account page and pretend checkout added after; the owner tried them too |
| management-app (Flutter) | Built (issue 12), 15 tests, checked against the running services. The owner tried it: it works (`manager1` / `manager123`) |
| Customer account page + pretend checkout | Built 2026-11-17, beyond the PRD (asked for by the owner). No card details are ever asked for or stored. Preferences in `%APPDATA%\CSCE310 Bookstore\preferences.json` |
| **Next** | M5 (issue 13): test every requirement FR1–FR14, N1–N5 end to end; then issue 14, final docs and v1.0.0. `manual_check.py` now covers every order endpoint (41 checks) |
| Testing and final release | M5 |

Known unfinished or unverified things: the "Known gaps" table at the end of `docs/03-problems/problem-log.md`.

## Standing rules from the owner

These override any plugin or skill that says otherwise.

1. **Always commit and push** after every change, without asking. End commit messages with the attribution line the session provides.
2. **Document as you build**, in the same commit as the code. The full list is `docs/02-design/engineering-rules.md`. In short:
   - every class and file in a class diagram and in the file map (`docs/02-design/class-diagrams.md`);
   - anything that went wrong, including the assistant's own mistakes, in `docs/03-problems/problem-log.md`, marked "Who: assistant";
   - anything made better than required in `docs/03-problems/enhancement-log.md`, with the measured effect;
   - anything taken from outside (library, font, file, idea) in `REFERENCES.md`, with version and license read from the package itself.
3. **Maintainable and error-friendly code**: the same four layers in every service, one error shape, validation at the edge. Follow the two finished services as the pattern.
4. **UI/UX quality is the top priority.** The approved look is `docs/02-design/style-guide.md`, implemented in `clients/bookstore-ui`. Show screenshots and iterate; say plainly when something (such as how motion feels) cannot be judged from a screenshot.
5. **Diagrams are made in draw.io**: source `.drawio` plus exported `.png` in `docs/02-design/diagrams`. Look at every exported image before committing it. See `tools/diagrams/README.md`.
6. **Report honestly.** Say what was verified and what was not. Never describe a step as done before reading its output.

## Things that are not obvious

- **Do not ask for or handle the MySQL root password.** Services log in as the limited `bookstore_app` account; its generated password is in `services/.env`, which git ignores. Never commit `.env` or `*.local.sql`; check `git diff --cached --name-only` before committing.
- **Tech per service is fixed by the PRD** (section 4.1): user = Java HttpServer, book and order = Python Flask. Not negotiable (problem P-001).
- **Renting** costs 10% of the book price, for 7 days. Returning a rented book is not built.
- **The API the apps must use is `docs/02-design/api-design.md`**, which now matches the three built services. Note `emailQueued` (not `emailSent`) in the order response.
- **The order-service MySQL tests run in the real `bookstore` database** (the app account cannot create another) and use up order numbers. They only touch their own temporary user.
- **Review before committing.** A code review of order-service after its tests passed found ten things (P-015).
- **Email** (FR10) goes through Gmail SMTP. The owner creates the Gmail app password themselves and puts it in `services/.env`.
- **Services listen on both `127.0.0.1` and `::1`**, never the network (P-004). Flask services run under waitress.
- **Measure from a cold start against the real database**, not only in tests (P-004, P-005). N1 allows 500 ms.
- **Write manual checks in Python**, stating the expected result of each call. A PowerShell check once failed silently and left a service running (P-014). After any run, confirm no service process is left.

## This machine

- Windows 11. **Use the PowerShell tool; the Bash tool has been failing.** In PowerShell, quote carefully and prefer writing a script to a file and running it.
- New terminals need the refreshed PATH: `$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')`.
- Tools and versions: `docs/05-setup/environment.md`.
- Smart App Control is on and blocks some unsigned programs (P-002, P-003). Do not turn it off. Retry once; otherwise use a signed alternative.
- Windows Developer Mode is off. Flutter needs it for plugins; it is the owner's setting to change. The apps deliberately use no plugins (E-035), so it is not needed.
- **Flutter release builds are blocked** by Smart App Control (P-017). Use debug builds (`flutter run`, `flutter build windows --debug`).
- **Format Dart at 150 columns** (`dart format -l 150`), the width the code is written in. Plain `dart format` rewrites untouched files.
- **The assistant cannot see or click the app window without the owner's approval** (computer use). To check the look, use `screenshots_test.dart`, and look at every image.

## How to run things

| What | Command (from the folder shown) |
|---|---|
| user-service tests and jar | `services/user-service`: `mvn package` |
| user-service | `java -jar target/user-service-0.3.0.jar` |
| book-service tests | `services/book-service`: `python -m unittest discover -s tests -t .` |
| book-service | `python -m book_service` |
| order-service tests | `services/order-service`: `python -m unittest discover -s tests -t .` |
| order-service | `python -m order_service` |
| All three services, checked for real | `services/order-service`: `python manual_check.py` (starts and stops them itself; ports 8081–8083 must be free) |
| Customer app | `clients/customer-app`: `flutter run -d windows` (needs the services running) |
| Customer app tests | `clients/customer-app`: `flutter test` |
| Management app, and its tests | `clients/management-app`: `flutter run -d windows`, `flutter test` |
| Shared package tests | `clients/bookstore-ui`: `flutter test` |
| Owner's Terminal panel cannot read the pub cache | Build with `flutter build windows --debug`, run `build\windows\x64\runner\Debug\<app>.exe` |
| Redraw the app screenshots | `clients/customer-app`: `set BOOKSTORE_SCREENSHOTS=1 && flutter test test/screenshots_test.dart` |
| Reset test data | repo root: `python database/seed.py` |

## Installed plugins

The owner installed Ponytail, Superpowers, Planning with Files, UI/UX Pro Max, Visual Explainer, Trail of Bits (two plugins), and Matt Pocock's skills. Use them where they help. Where one conflicts with the standing rules above, the standing rules win: for example, Ponytail's "comment only the why" does not remove the documentation rule.
