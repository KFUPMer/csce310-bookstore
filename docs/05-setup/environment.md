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
| MongoDB Shell | 2.14.1 | Optional: looking at the data by hand | `winget install MongoDB.Shell` | blocked by Smart App Control, see P-003 |
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

### MySQL — one command left, to be run by the machine's owner

The services do **not** use the MySQL root account. They log in as `bookstore_app`, an account that can only read and write the `bookstore` database. Its password is generated on this machine and kept in `services/.env`, which git ignores. The root password is typed once, by its owner, and is never stored or shared.

1. Generate the local setup (already done on this machine; safe to repeat):

```bash
python database/make_local_setup.py
```

   It writes `services/.env` and `database/mysql/setup.local.sql` (the tables plus the `bookstore_app` account). Both are ignored by git.

2. Run the setup as root, in **Command Prompt** from the project folder. It asks for the root password:

```bash
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p < database\mysql\setup.local.sql
```

3. Load the test accounts and books:

```bash
python database/seed.py
```

Why not just use root: an application should have only the access it needs. If the app account's password leaked, only the bookstore data would be exposed, not the whole MySQL server.

## Starting on a fresh terminal

PATH changes only apply to terminals opened after the install. If `flutter`, `mvn`, or `java` is "not recognized", close and reopen the terminal (and restart VS Code).

## Windows Smart App Control

Smart App Control is **on** on this machine. It blocks programs that are unsigned and unknown to Microsoft. So far it has blocked the MongoDB shell (P-003) and, once, a Flutter build tool (P-002).

It is left on. Turning it off is permanent: Windows only lets it be re-enabled by reinstalling Windows. If something this project really needs gets blocked:

1. Try again once (this fixed P-002).
2. Use a signed alternative (for looking at MongoDB data: MongoDB Compass, or the MongoDB extension for VS Code).
3. Only then consider switching it off, in Windows Security → App & browser control → Smart App Control. This is the machine owner's decision.
