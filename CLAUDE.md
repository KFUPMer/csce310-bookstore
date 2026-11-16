# CSCE310 Bookstore: notes for the AI assistant

Read this first. It is what a new session needs to carry on without the earlier conversation.

## What this is

A course project, done individually, due **2026-12-04**. An online bookstore: three backend services and two Flutter desktop apps. The repo must show the *process* (idea, design, problems, plan), not only code. The owner must be able to explain everything in it.

Requirements are in `docs/01-idea/project-idea.md` (FR1–FR14, N1–N5, from the course PRD). Every extra-credit item is being done.

## Where things stand

The live plan is `docs/04-planning/milestones.md`; tasks are GitHub issues on `KFUPMer/csce310-bookstore` (use `gh`).

| Part | State |
|---|---|
| M1 Idea, M2 Design | Closed. Released as v0.1.0 and v0.2.0 |
| user-service (Java HttpServer, MySQL) | Done, verified against MySQL |
| book-service (Python Flask, MongoDB) | Done, verified on the running service |
| **order-service (Python Flask, MySQL)** | **Not started. This is next** (issues 10, 16, 7) |
| customer-app, management-app (Flutter) | Only a style preview of one screen exists (`SearchScreen`, on sample data). M4 |
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
- **Email** (FR10) goes through Gmail SMTP. The owner creates the Gmail app password themselves and puts it in `services/.env`.
- **Services listen on both `127.0.0.1` and `::1`**, never the network (P-004). Flask services run under waitress.
- **Measure from a cold start against the real database**, not only in tests (P-004, P-005). N1 allows 500 ms.
- **Write manual checks in Python**, stating the expected result of each call. A PowerShell check once failed silently and left a service running (P-014). After any run, confirm no service process is left.

## This machine

- Windows 11. **Use the PowerShell tool; the Bash tool has been failing.** In PowerShell, quote carefully and prefer writing a script to a file and running it.
- New terminals need the refreshed PATH: `$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')`.
- Tools and versions: `docs/05-setup/environment.md`.
- Smart App Control is on and blocks some unsigned programs (P-002, P-003). Do not turn it off. Retry once; otherwise use a signed alternative.
- Windows Developer Mode is off. Flutter needs it for plugins; it is the owner's setting to change.

## How to run things

| What | Command (from the folder shown) |
|---|---|
| user-service tests and jar | `services/user-service`: `mvn package` |
| user-service | `java -jar target/user-service-0.3.0.jar` |
| book-service tests | `services/book-service`: `python -m unittest discover -s tests -t .` |
| book-service | `python -m book_service` |
| Customer app | `clients/customer-app`: `flutter run -d windows` |
| Reset test data | repo root: `python database/seed.py` |

## Installed plugins

The owner installed Ponytail, Superpowers, Planning with Files, UI/UX Pro Max, Visual Explainer, Trail of Bits (two plugins), and Matt Pocock's skills. Use them where they help. Where one conflicts with the standing rules above, the standing rules win: for example, Ponytail's "comment only the why" does not remove the documentation rule.
