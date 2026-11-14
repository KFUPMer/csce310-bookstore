"""Prepare this machine's database setup, without anyone sharing the MySQL root password.

Creates two files that are ignored by git:

  database/mysql/setup.local.sql   the schema plus a dedicated MySQL account for the services
  services/.env                    the settings the services read, including that account's password

The services then log in as `bookstore_app`, an account that can only read and
write the `bookstore` database. The root password is typed once, by its owner,
when running setup.local.sql, and is never stored anywhere.

Run:  python database/make_local_setup.py
Safe to run again: it keeps an existing services/.env and reuses its password.
"""
import secrets
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENV = ROOT / "services" / ".env"
ENV_EXAMPLE = ROOT / "services" / ".env.example"
SCHEMA = ROOT / "database" / "mysql" / "schema.sql"
SETUP = ROOT / "database" / "mysql" / "setup.local.sql"
APP_USER = "bookstore_app"


def read_env(path):
    values = {}
    if path.exists():
        for line in path.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                name, value = line.split("=", 1)
                values[name.strip()] = value.strip()
    return values


def main():
    existing = read_env(ENV)
    password = existing.get("MYSQL_PASSWORD") if existing.get("MYSQL_USER") == APP_USER else None
    password = password or secrets.token_urlsafe(24)
    service_key = existing.get("SERVICE_KEY") or secrets.token_urlsafe(24)

    # services/.env: start from the example, fill in what this script owns, keep anything already set.
    lines = []
    for line in ENV_EXAMPLE.read_text(encoding="utf-8").splitlines():
        name = line.split("=", 1)[0].strip() if "=" in line and not line.strip().startswith("#") else None
        if name == "MYSQL_USER":
            line = f"MYSQL_USER={APP_USER}"
        elif name == "MYSQL_PASSWORD":
            line = f"MYSQL_PASSWORD={password}"
        elif name == "SERVICE_KEY":
            line = f"SERVICE_KEY={service_key}"
        elif name and existing.get(name):
            line = f"{name}={existing[name]}"
        lines.append(line)
    ENV.write_text("\n".join(lines) + "\n", encoding="utf-8")

    SETUP.write_text(
        SCHEMA.read_text(encoding="utf-8")
        + f"""
-- A dedicated account for the services: it can use the bookstore database and nothing else.
CREATE USER IF NOT EXISTS '{APP_USER}'@'localhost' IDENTIFIED BY '{password}';
ALTER USER '{APP_USER}'@'localhost' IDENTIFIED BY '{password}';
GRANT SELECT, INSERT, UPDATE, DELETE ON bookstore.* TO '{APP_USER}'@'localhost';
FLUSH PRIVILEGES;
""",
        encoding="utf-8",
    )
    print(f"Wrote {ENV.relative_to(ROOT)} and {SETUP.relative_to(ROOT)} (both ignored by git).")
    print("Next, run this and type your MySQL root password when asked:")
    print(r'  "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p < database\mysql\setup.local.sql')


if __name__ == "__main__":
    main()
