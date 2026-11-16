"""Sends one real bill email, end to end (FR10).

Run from services/order-service, with SMTP_USER and SMTP_PASSWORD filled in
in services/.env and nothing listening on ports 8081-8083:

    python email_check.py

Starts the three services, registers a temporary customer whose email is the
sending address itself (so the bill arrives in your own inbox), places one
order, and waits for order-service's log to say whether the email was sent.
Then deletes the order, its bill file, and the customer, gives the copy back,
and stops the services. Prints no address and no password.
"""
import secrets
import subprocess
import sys
import tempfile
import time
from pathlib import Path

import requests

from manual_check import BOOK, HERE, ORDER, PORTS, SERVICES, USER, clean_up, login, port_is_open, start
from order_service.config import Config

WAIT_SECONDS = 40


def main() -> int:
    config = Config.load()
    if not config.email_is_configured:
        print("SMTP_USER or SMTP_PASSWORD is empty in services/.env: nothing to check.")
        return 2
    busy = [port for port in PORTS if port_is_open(port)]
    if busy:
        print(f"Ports already in use: {busy}.")
        return 2

    logs = Path(tempfile.mkdtemp(prefix="email-check-"))
    processes: list[subprocess.Popen] = []
    order_ids: list[int] = []
    taken: dict[str, int] = {}
    temp_user = "mail_" + secrets.token_hex(4)
    outcome = "no order was placed"
    try:
        processes.append(start("user-service", ["java", "-jar", "target/user-service-0.3.0.jar"], SERVICES / "user-service", 8081, logs))
        processes.append(start("book-service", [sys.executable, "-m", "book_service"], SERVICES / "book-service", 8082, logs))
        processes.append(start("order-service", [sys.executable, "-m", "order_service"], HERE, 8083, logs))

        password = secrets.token_urlsafe(12)
        registered = requests.post(f"{USER}/api/users/register", json={"username": temp_user, "email": config.smtp_user, "password": password}, timeout=10)
        if registered.status_code != 201:
            print(f"Could not register the temporary customer: {registered.status_code} {registered.json().get('error')}")
            return 1
        customer = login({"username": temp_user, "password": password})
        book = next(b for b in requests.get(f"{BOOK}/api/books", headers=customer, timeout=10).json() if b["copiesAvailable"] >= 1)

        placed = requests.post(f"{ORDER}/api/orders", json={"items": [{"bookId": book["id"], "type": "RENT"}]}, headers=customer, timeout=10)
        took = placed.elapsed.total_seconds() * 1000
        if placed.status_code != 201:
            print(f"The order was refused: {placed.status_code} {placed.text[:200]}")
            return 1
        order = placed.json()
        order_ids.append(order["id"])
        taken[book["id"]] = 1
        print(f"Order {order['id']} placed in {took:.0f} ms (renting '{book['title']}'), emailQueued = {order['emailQueued']}")

        # The email is sent after the answer, on a background thread: its result is only in the log.
        log_file = logs / "order-service.log"
        deadline = time.monotonic() + WAIT_SECONDS
        outcome = f"no result in the log after {WAIT_SECONDS} seconds"
        while time.monotonic() < deadline:
            lines = [line for line in log_file.read_text(encoding="utf-8", errors="replace").splitlines() if f"order {order['id']}" in line and "mail" in line.lower()]
            if lines:
                outcome = lines[-1].split(": ", 1)[-1]
                break
            time.sleep(0.5)
    finally:
        clean_up(config, order_ids, taken, temp_user, processes, logs)
        for process in processes:
            if process.poll() is None:
                process.terminate()
        for process in processes:
            try:
                process.wait(10)
            except subprocess.TimeoutExpired:
                process.kill()
        time.sleep(0.5)
        print(f"services left running on ports: {[port for port in PORTS if port_is_open(port)]}")

    sent = outcome.startswith("Emailed the bill")
    print(f"RESULT: {outcome}")
    print("EMAIL SENT: check the inbox of the sending address" if sent else "EMAIL NOT SENT")
    return 0 if sent else 1


if __name__ == "__main__":
    sys.exit(main())
