# Development environment

What is installed on the development machine, how it got there, and how to check it. Windows 11.

## Tools

| Tool | Version | Needed for | Installed with | Check |
|---|---|---|---|---|
| Git | 2.56 | Version control | Already present | `git --version` |
| GitHub CLI | 2.97 | Issues, milestones, releases | Already present | `gh --version` |
| VS Code | — | Editor | Already present | — |
| MySQL Server | 8.0.46 | Users, sessions, orders | Already present (service `MySQL80`, port 3306) | see below |
| Python | 3.12.10 | book-service, order-service, seed script | Already present | `python --version` |
| Java JDK (Eclipse Temurin) | 21.0.13 | user-service | `winget install EclipseAdoptium.Temurin.21.JDK` | `java -version` |
| Maven | 3.9.9 | Building user-service | Downloaded from archive.apache.org (checksum verified), unpacked to `%USERPROFILE%\develop`, added to PATH | `mvn -version` |
| MongoDB Server | 9.0.4 | Books | `winget install MongoDB.Server` (service `MongoDB`, port 27017, this machine only) | see below |
| MongoDB Shell | 2.14.1 | Optional: looking at the data by hand | `winget install MongoDB.Shell` | blocked, see P-003 |
| Flutter SDK | 3.50.0 (Dart 3.14) | Both desktop apps | Cloned from github.com/flutter/flutter (stable) to `%USERPROFILE%\develop\flutter`, added to PATH | `flutter doctor` |
| Visual Studio 2022 Build Tools | 17.14 | Compiling Flutter Windows apps | `winget install Microsoft.VisualStudio.2022.BuildTools` with the C++ desktop workload | `flutter doctor` |
| draw.io Desktop | 32.6 | All diagrams | `winget install JGraph.Draw` | — |

VS Code extensions: Flutter, Dart.

## Python packages

| Package | Used for |
|---|---|
| `flask` | The two Python web services |
| `mysql-connector-python` | order-service and the seed script talking to MySQL |
| `pymongo` | book-service and the seed script talking to MongoDB |
| `bcrypt` | Hashing the test accounts' passwords in the seed script |
| `requests` | One service calling another |

```bash
pip install flask mysql-connector-python pymongo bcrypt requests
```

## Databases

### MongoDB — done

The 15 sample books are loaded and the indexes on `title` and `author` exist. Checked on 2026-11-13: a search for "java" returns 3 books.

### MySQL — one step left, to be done by hand

The `bookstore` database is not created yet, because that needs the MySQL root password, which is only typed by its owner.

1. Create the database and tables (asks for the root password):

```bash
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p < database/mysql/schema.sql
```

2. Put the MySQL settings in `services/.env` (copy `services/.env.example`). This file is ignored by git.
3. Load the test accounts and books: `python database/seed.py`

## Starting on a fresh terminal

PATH changes only apply to terminals opened after the install. If `flutter`, `mvn`, or `java` is "not recognized", close and reopen the terminal (and restart VS Code).
