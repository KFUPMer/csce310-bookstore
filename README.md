# CSCE310 Project — Bookstore

An online bookstore: customers search for books and place orders from a desktop app, and managers handle books, orders, and payment status from a second desktop app. Behind them are RESTful web services (Java HttpServer and Python Flask) using MySQL and MongoDB.

This repository records the **whole process** of the project, not only the final code: the idea, the design, the problems we hit and how we solved them, and the plan (milestones, tasks, deadlines, versions).

## Project status

| Phase | Milestone | Version | Status |
|---|---|---|---|
| 1. Idea & requirements | M1 | v0.1.0 | Done — released 2026-11-13 |
| 2. Design | M2 | v0.2.0 | Done — released 2026-11-13 |
| 3. Backend services | M3 | v0.3.0 | Not started |
| 4. Desktop clients | M4 | v0.4.0 | Not started |
| 5. Testing & final release | M5 | v1.0.0 | Not started |

Dates and tasks: [docs/04-planning/milestones.md](docs/04-planning/milestones.md)

## How to read this repository

| Folder | What is in it |
|---|---|
| [docs/01-idea](docs/01-idea/project-idea.md) | What we are building and why; scope and requirements |
| [docs/02-design](docs/02-design/architecture.md) | [Architecture](docs/02-design/architecture.md), [use cases](docs/02-design/use-cases.md), [UML diagrams](docs/02-design/uml-diagrams.md), [database](docs/02-design/database-design.md), [API](docs/02-design/api-design.md), [UI](docs/02-design/ui-design.md), [style guide](docs/02-design/style-guide.md), [bill](docs/02-design/bill-design.md) |
| [database/](database/README.md) | MySQL schema, sample books, and the seed script |
| [docs/02-design/engineering-rules.md](docs/02-design/engineering-rules.md) | How the code is written: documentation, layers, error handling, tests |
| [docs/03-problems](docs/03-problems/problem-log.md) | The [problem log](docs/03-problems/problem-log.md): what went wrong, who caused it, how it was fixed. The [enhancement log](docs/03-problems/enhancement-log.md): what was made better than required, and why |
| [docs/04-planning](docs/04-planning/milestones.md) | Milestones, tasks, deadlines, versioning rules |
| [docs/05-setup](docs/05-setup/environment.md) | The development environment: every tool, its version, and how to check it |
| `services/` | Backend RESTful web services |
| `clients/` | The two desktop GUI applications |
| [CHANGELOG.md](CHANGELOG.md) | What changed in every version and patch |
| [REFERENCES.md](REFERENCES.md) | Everything that came from someone else, with its source and license |
| [LICENSE](LICENSE) | The MIT License, which covers this project's own work |

## Tech stack

| Layer | Choice |
|---|---|
| User service | Java (built-in HttpServer), Maven |
| Book service | Python, Flask |
| Order and billing service | Python, Flask |
| Relational database | MySQL |
| Document database | MongoDB |
| Desktop clients (customer, manager) | Flutter (Dart), Windows desktop |
| Version control | Git + GitHub (milestones, issues, releases) |

## Workflow

1. Every task is a GitHub issue attached to a milestone with a deadline.
2. Work happens on a branch named after the task, e.g. `feature/12-catalog-search` or `fix/27-order-total`.
3. The branch is merged into `main` through a pull request that closes the issue.
4. When a milestone is complete, `main` is tagged with a version and a GitHub release is published.
5. Any problem that costs real time gets an entry in the [problem log](docs/03-problems/problem-log.md), and any improvement beyond the requirements an entry in the [enhancement log](docs/03-problems/enhancement-log.md).
6. Anything taken from outside is listed in [REFERENCES.md](REFERENCES.md) with its license.

Versioning rules are in [docs/04-planning/versioning.md](docs/04-planning/versioning.md).

## License

This project's own code, documents, and diagrams are under the [MIT License](LICENSE). Third-party fonts and libraries keep their own licenses, listed in [REFERENCES.md](REFERENCES.md).
