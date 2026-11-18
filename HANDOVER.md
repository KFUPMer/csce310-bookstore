# CSCE310 Bookstore: handover

For the instructor. Everything needed to install, try, and grade the project, and where to find the evidence for each part. Individual project; deadline 2026-12-04.

**Repository:** https://github.com/KFUPMer/csce310-bookstore · **Install:** [INSTALL.md](INSTALL.md) · **Build to install:** the newest release on the [releases page](https://github.com/KFUPMer/csce310-bookstore/releases)

## In one paragraph

An online bookstore built to the course PRD: three RESTful services and two native desktop apps. **user-service** (Java HttpServer, MySQL) handles accounts, login, sessions, and roles. **book-service** (Python Flask, MongoDB) handles searching and managing books. **order-service** (Python Flask, MySQL) handles orders, HTML bills, emailing the bills, and payment status. **Bookstore** is the customer app and **Bookstore Manager** the manager app, both in Flutter. All 14 functional and 5 non-functional requirements are met and tested, together with every extra-credit item. 225 automated tests and 41 checks against the running services pass.

## Trying it (about 15 minutes)

[INSTALL.md](INSTALL.md) has the full steps. In short, on Windows 10 or 11:

1. Have MySQL Server 8 installed (the one prerequisite installed by hand).
2. From the release, download `Bookstore-Server-…zip` and `Bookstore-Apps-Setup-…exe`.
3. In the unzipped server folder, double-click `setup.cmd`. It installs anything missing (Java, Python, MongoDB) and creates the data. It asks one thing: your MySQL root password, once, typed into MySQL itself.
4. Double-click `start-services.cmd`, then run the apps installer.
5. Log in: customer `customer1` / `customer123`; manager `manager1` / `manager123`.

### A five-minute walk through every requirement

| Step | Do this | Shows |
|---|---|---|
| 1 | Open **Bookstore**, click "Create an account" and register a new customer | FR3 (extra credit), N3 |
| 2 | Log in as that customer | FR1, FR2 |
| 3 | Type "java" in the search; switch to the list view | FR4, FR5 |
| 4 | Open a book and **Buy** it; open another and **Rent for 7 days** | FR6, FR7 |
| 5 | **Your order** → **Place order**: the bill opens | FR7, FR8 |
| 6 | The bill is saved as `services\order-service\bills\bill-<id>.html`, and emailed if a Gmail app password is set ([INSTALL.md](INSTALL.md), optional) | FR9, FR10 (extra credit) |
| 7 | Try to log in to **Bookstore Manager** with the customer account: it is refused | FR11, N5 |
| 8 | Log in to **Bookstore Manager** as `manager1`: every order is listed | FR11, FR12 |
| 9 | Click **Mark as paid** on the new order; open it to see its bill and **Print** it | FR13, FR9 |
| 10 | **Books** tab: add a book, or change a book's copies; search for it in Bookstore | FR14 |
| 11 | Every action answers at once, and the windows never freeze while waiting | N1, N2 |

N4 (a token on every request) and N5 (each role limited to its own data) are enforced by the services; the [requirements test report](docs/06-testing/requirements-test.md) shows the tests and live checks for each.

## Where to find what

| You want | Look at |
|---|---|
| Each requirement and the evidence that it works | [docs/06-testing/requirements-test.md](docs/06-testing/requirements-test.md) |
| The requirements as received, and the decisions about them | [docs/01-idea/project-idea.md](docs/01-idea/project-idea.md) |
| Architecture and the reasons for each decision | [docs/02-design/architecture.md](docs/02-design/architecture.md) |
| UML: use case, class (one per service and app), sequence (4), activity (3), state machine, component, object, profile, ER, wireframes. 23 diagrams in draw.io, source and image | [docs/02-design/uml-diagrams.md](docs/02-design/uml-diagrams.md), [class-diagrams.md](docs/02-design/class-diagrams.md) |
| Use case descriptions | [docs/02-design/use-cases.md](docs/02-design/use-cases.md) |
| Database (MySQL and MongoDB) | [docs/02-design/database-design.md](docs/02-design/database-design.md), [database/](database/README.md) |
| Every endpoint, its request, answer, and errors | [docs/02-design/api-design.md](docs/02-design/api-design.md) |
| The visual design and its accessibility (color-blind safe, Nielsen's 10 heuristics), with screenshots of every screen | [docs/02-design/style-guide.md](docs/02-design/style-guide.md) |
| How the code is written (four layers in every service, one error shape) | [docs/02-design/engineering-rules.md](docs/02-design/engineering-rules.md) |
| What went wrong, who caused it, and how it was fixed | [docs/03-problems/problem-log.md](docs/03-problems/problem-log.md) |
| What was made better than required, with the measured effect | [docs/03-problems/enhancement-log.md](docs/03-problems/enhancement-log.md) |
| The plan, milestones, and dated progress notes | [docs/04-planning/milestones.md](docs/04-planning/milestones.md), plus the repository's GitHub milestones, issues, and releases |
| Every version and what changed | [CHANGELOG.md](CHANGELOG.md) |
| Tools and versions on the development machine | [docs/05-setup/environment.md](docs/05-setup/environment.md) |
| Everything from outside, with its license; the use of an AI assistant | [REFERENCES.md](REFERENCES.md) |
| Each service's and app's own README (run, test, how it is built) | `services/*/README.md`, `clients/*/README.md` |

## The PRD's fixed choices, and how they were met

| PRD | This project |
|---|---|
| RESTful services | Three services, JSON over HTTP, one error shape `{ "error": "…" }` |
| Java HttpServer and Python Flask | user-service: Java 21 with the built-in `com.sun.net.httpserver`. book-service and order-service: Flask, served by waitress |
| MySQL and MongoDB | MySQL: users, sessions, orders, order items. MongoDB: books |
| Two native desktop GUI apps | Flutter (Windows); no web pages |
| Bill as HTML, saved, printable | Saved per order; the manager app prints it in the browser |

## Extra credit claimed

| Item | Where |
|---|---|
| FR3: user registration (+1%) | `POST /api/users/register` in user-service; the "Create an account" screen |
| FR10: email the bill (+1%) | order-service sends the HTML bill through Gmail SMTP in the background. A real email was received and checked in Gmail (problem log P-016) |
| Modern GUI framework (+2%) | Flutter, with a design system shared by both apps (`clients/bookstore-ui`) |

Beyond the PRD, at the owner's request: a customer **account page** (order history, profile, preferences, rentals due back) and a **demonstration checkout** that marks an order as paid. It asks for no card details. The PRD's manager payment flow (FR13) is unchanged.

## Process

- **Milestones M1 to M5**, each closed with a tagged GitHub release (v0.1.0 to v0.4.0, then v1.0.0-beta.1), most well before their deadlines. Dated notes in [milestones.md](docs/04-planning/milestones.md).
- **Tasks as GitHub issues**, each closed with a note of what was done.
- **17 problem-log entries**, including the assistant's own mistakes, and **44 enhancement-log entries**, each with its reason and measured effect.
- **Tests with the code**: every service and app has its own tests, run again for each release; order-service and the later app features were written test-first. A code review before committing found what the tests had not (P-015).

## Known limits

Listed honestly so nothing is a surprise. The full list is under "Known gaps" at the end of the [problem log](docs/03-problems/problem-log.md).

- **Windows only.** The apps are built for Windows desktop.
- **The installer is not code-signed**, so Windows shows an "unknown publisher" warning (More info → Run anyway). On a computer with **Smart App Control** on, Windows blocks it outright, as it did on the development computer. [INSTALL.md](INSTALL.md) gives the way round: building the apps from the source. The installer itself is tested on GitHub's Windows machine before each release (install, open both apps, uninstall).
- **Returning a rented book is not built**; the PRD does not ask for it. A manager can raise the number of copies.
- **Sessions end only at logout**, which is exactly what FR2 asks.
- **Not tested:** screen readers, and the bill email in mail programs other than Gmail on the web.

## Use of an AI assistant

Much of the code, documentation, and diagrams was produced with Claude (Anthropic) as a coding assistant, directed by the project owner. The owner made every decision and approval: technology, visual style, scope. Those commits carry `Co-Authored-By: Claude`, and the assistant's mistakes are logged as such. Details in [REFERENCES.md](REFERENCES.md#6-use-of-an-ai-assistant).
