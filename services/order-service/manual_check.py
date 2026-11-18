"""Checks order-service for real: all three services running, the real MySQL and MongoDB.

Run from services/order-service, with nothing listening on ports 8081-8083:

    python manual_check.py

It starts user-service, book-service, and order-service, calls every endpoint
the way the apps will, and prints for each call what it expected, what it got,
and how long it took. The first order is placed straight after start-up, so its
time is the cold-start time (N1 allows 500 ms).

It cleans up after itself: the orders it placed, their bill files, and its
temporary customer are deleted, the copies it took are given back, and the
three services are stopped. The last line says whether every check passed.
"""
import secrets
import socket
import subprocess
import sys
import tempfile
import time
from decimal import ROUND_HALF_UP, Decimal
from pathlib import Path

import mysql.connector
import requests

from order_service.config import Config

HERE = Path(__file__).resolve().parent
SERVICES = HERE.parent
USER, BOOK, ORDER = "http://127.0.0.1:8081", "http://127.0.0.1:8082", "http://localhost:8083"
PORTS = (8081, 8082, 8083)
N1_LIMIT_MS = 500

# The seeded test accounts (database/seed.py).
CUSTOMER = {"username": "customer1", "password": "customer123"}
MANAGER = {"username": "manager1", "password": "manager123"}

results: list[bool] = []
slowest = 0.0


def port_is_open(port: int) -> bool:
    with socket.socket() as probe:
        probe.settimeout(0.3)
        return probe.connect_ex(("127.0.0.1", port)) == 0


def start(name: str, command: list[str], folder: Path, port: int, logs: Path) -> subprocess.Popen:
    log = open(logs / f"{name}.log", "w", encoding="utf-8")
    process = subprocess.Popen(command, cwd=folder, stdout=log, stderr=subprocess.STDOUT)
    deadline = time.monotonic() + 40
    while not port_is_open(port):
        if process.poll() is not None or time.monotonic() > deadline:
            process.kill()
            raise RuntimeError(f"{name} did not start. Its log: {logs / (name + '.log')}")
        time.sleep(0.1)
    return process


def check(what: str, response: requests.Response, expected_status: int, also=lambda r: True, timed: bool = True) -> requests.Response:
    """One call: print what was expected and what came back. `also` checks the body."""
    global slowest
    took = response.elapsed.total_seconds() * 1000
    try:
        ok = response.status_code == expected_status and bool(also(response))
    except Exception:  # noqa: BLE001 - a body in an unexpected shape is a failed check, not a crash
        ok = False
    if timed:
        ok = ok and took < N1_LIMIT_MS
        slowest = max(slowest, took)
    results.append(ok)
    detail = "" if ok else f"   <-- got {response.status_code} {response.text[:160]!r}"
    print(f"{'PASS' if ok else 'FAIL'}  {took:6.0f} ms  expected {expected_status}  {what}{detail}")
    return response


def expect(what: str, condition: bool) -> None:
    results.append(bool(condition))
    print(f"{'PASS' if condition else 'FAIL'}             {what}")


def login(account: dict) -> dict:
    response = requests.post(f"{USER}/api/auth/login", json=account, timeout=10)
    response.raise_for_status()
    return {"Authorization": "Bearer " + response.json()["token"]}


def main() -> int:
    config = Config.load()
    busy = [port for port in PORTS if port_is_open(port)]
    if busy:
        print(f"Ports already in use: {busy}. Stop whatever is listening there and run again.")
        return 2

    logs = Path(tempfile.mkdtemp(prefix="order-check-"))
    processes: list[subprocess.Popen] = []
    order_ids: list[int] = []
    taken: dict[str, int] = {}
    temp_user = "check_" + secrets.token_hex(4)
    try:
        processes.append(start("user-service", ["java", "-jar", "target/user-service.jar"], SERVICES / "user-service", 8081, logs))
        processes.append(start("book-service", [sys.executable, "-m", "book_service"], SERVICES / "book-service", 8082, logs))
        order_process = start("order-service", [sys.executable, "-m", "order_service"], HERE, 8083, logs)
        processes.append(order_process)
        book_process = processes[1]

        customer, manager = login(CUSTOMER), login(MANAGER)
        password = secrets.token_urlsafe(12)
        requests.post(f"{USER}/api/users/register", json={"username": temp_user, "email": f"{temp_user}@example.com", "password": password}, timeout=10).raise_for_status()
        other = login({"username": temp_user, "password": password})

        books = requests.get(f"{BOOK}/api/books", headers=customer, timeout=10).json()
        # At least 4: the first book loses 1 + 2 copies to the two orders and needs one more for the 404 check.
        in_stock = [book for book in books if book["copiesAvailable"] >= 4]
        first, second = in_stock[0], in_stock[1]
        before = {book["id"]: book["copiesAvailable"] for book in books}

        def copies(book_id: str) -> int:
            return requests.get(f"{BOOK}/api/books/{book_id}", headers=customer, timeout=10).json()["copiesAvailable"]

        print(f"\n--- place an order (the first call is the cold start; N1 allows {N1_LIMIT_MS} ms)")
        # Worked out here, separately from the service: 10% of the price, to the cent, half up.
        rent = float((Decimal(str(second["price"])) * Decimal("0.10")).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))
        expected_total = round(first["price"] + rent, 2)
        body = {"items": [{"bookId": first["id"], "type": "BUY"}, {"bookId": second["id"], "type": "RENT"}]}
        placed = check(
            f"customer buys '{first['title']}' and rents '{second['title']}': total {expected_total}",
            requests.post(f"{ORDER}/api/orders", json=body, headers=customer, timeout=10), 201,
            lambda r: r.json()["total"] == expected_total and r.json()["paymentStatus"] == "PENDING" and r.json()["items"][1]["unitPrice"] == rent
            and r.json()["items"][1]["rentDueDate"] and r.json()["username"] == "customer1",
        )
        order = placed.json()
        if placed.status_code == 201:
            order_ids.append(order["id"])
            taken[first["id"]] = taken.get(first["id"], 0) + 1
            taken[second["id"]] = taken.get(second["id"], 0) + 1
        order_id = order.get("id", 0)
        expect("one copy of each book was taken", copies(first["id"]) == before[first["id"]] - 1 and copies(second["id"]) == before[second["id"]] - 1)
        bill_path = config.bills_folder / f"bill-{order_id}.html"
        expect(f"the bill was saved as {order.get('billFile')}", order.get("billFile") == f"bills/bill-{order_id}.html" and bill_path.is_file() and bill_path.read_text(encoding="utf-8") == order.get("billHtml"))
        expect(f"emailQueued is {config.email_is_configured} (email is {'set up' if config.email_is_configured else 'not set up'} in .env)", order.get("emailQueued") == config.email_is_configured)

        again = check(
            "a second order, the same book twice: one line with quantity 2",
            requests.post(f"{ORDER}/api/orders", json={"items": [{"bookId": first["id"], "type": "BUY"}] * 2}, headers=other, timeout=10), 201,
            lambda r: r.json()["items"][0]["quantity"] == 2 and r.json()["total"] == round(first["price"] * 2, 2) and r.json()["id"] == order_id + 1,
        )
        if again.status_code == 201:
            order_ids.append(again.json()["id"])
            taken[first["id"]] = taken.get(first["id"], 0) + 2

        print("\n--- orders that must be refused")
        check("no token", requests.post(f"{ORDER}/api/orders", json=body, timeout=10), 401)
        check("a token that is not a session", requests.post(f"{ORDER}/api/orders", json=body, headers={"Authorization": "Bearer nonsense"}, timeout=10), 401)
        check("a manager cannot place an order", requests.post(f"{ORDER}/api/orders", json=body, headers=manager, timeout=10), 403)
        check("no items", requests.post(f"{ORDER}/api/orders", json={"items": []}, headers=customer, timeout=10), 400)
        check("a type that is not BUY or RENT", requests.post(f"{ORDER}/api/orders", json={"items": [{"bookId": first["id"], "type": "KEEP"}]}, headers=customer, timeout=10), 400)
        check("a body that is not JSON", requests.post(f"{ORDER}/api/orders", data="hello", headers=customer, timeout=10), 400)
        now_first = copies(first["id"])
        check(
            "a real book and a book that does not exist: 404",
            requests.post(f"{ORDER}/api/orders", json={"items": [{"bookId": first["id"], "type": "BUY"}, {"bookId": "f" * 24, "type": "BUY"}]}, headers=customer, timeout=10), 404,
        )
        expect("...and the copy of the real book was given back", copies(first["id"]) == now_first)
        sold_out = [book for book in books if book["copiesAvailable"] == 0]
        if sold_out:
            check(f"'{sold_out[0]['title']}' has no copies: 409", requests.post(f"{ORDER}/api/orders", json={"items": [{"bookId": sold_out[0]["id"], "type": "BUY"}]}, headers=customer, timeout=10), 409)
        else:
            too_many = [{"bookId": second["id"], "type": "BUY"}] * (copies(second["id"]) + 1)
            check(f"more copies of '{second['title']}' than there are: 409", requests.post(f"{ORDER}/api/orders", json={"items": too_many}, headers=customer, timeout=10), 409)
            expect("...and none were taken", copies(second["id"]) == before[second["id"]] - 1)

        print("\n--- the bill (FR8, FR9)")
        check("the owner opens the bill: the saved HTML", requests.get(f"{ORDER}/api/orders/{order_id}/bill", headers=customer, timeout=10), 200,
              lambda r: r.headers["Content-Type"].startswith("text/html") and r.content.decode("utf-8") == order["billHtml"])
        check("a manager opens the bill", requests.get(f"{ORDER}/api/orders/{order_id}/bill", headers=manager, timeout=10), 200)
        check("another customer cannot", requests.get(f"{ORDER}/api/orders/{order_id}/bill", headers=other, timeout=10), 403)
        check("the bill of an order that does not exist", requests.get(f"{ORDER}/api/orders/999999999/bill", headers=manager, timeout=10), 404)
        check("no token", requests.get(f"{ORDER}/api/orders/{order_id}/bill", timeout=10), 401)
        bill_path.unlink(missing_ok=True)
        check("after the file is deleted, the bill is made again, identical", requests.get(f"{ORDER}/api/orders/{order_id}/bill", headers=customer, timeout=10), 200,
              lambda r: r.content.decode("utf-8") == order["billHtml"] and bill_path.is_file())

        print("\n--- one order as JSON, a customer's own orders, and the pretend checkout (added in M4)")
        other_id = order_id + 1  # the temporary customer's order, placed above
        check("a manager gets one order with its items", requests.get(f"{ORDER}/api/orders/{order_id}", headers=manager, timeout=10), 200,
              lambda r: len(r.json()["items"]) == 2 and r.json()["email"] and "billHtml" not in r.json())
        check("another customer cannot get it", requests.get(f"{ORDER}/api/orders/{order_id}", headers=other, timeout=10), 403)
        check("a customer lists only their own orders", requests.get(f"{ORDER}/api/orders/mine", headers=other, timeout=10), 200,
              lambda r: [o["id"] for o in r.json()] == [other_id] and r.json()[0]["items"][0]["quantity"] == 2)
        check("a manager has no orders of their own", requests.get(f"{ORDER}/api/orders/mine", headers=manager, timeout=10), 403)
        check("a customer cannot pay someone else's order", requests.post(f"{ORDER}/api/orders/{order_id}/pay", headers=other, timeout=10), 403)
        check("a manager cannot use the customer's checkout", requests.post(f"{ORDER}/api/orders/{other_id}/pay", headers=manager, timeout=10), 403)
        check("the customer pays their own order", requests.post(f"{ORDER}/api/orders/{other_id}/pay", headers=other, timeout=10), 200,
              lambda r: r.json()["paymentStatus"] == "PAID")
        check("...and cannot pay it twice", requests.post(f"{ORDER}/api/orders/{other_id}/pay", headers=other, timeout=10), 409)

        print("\n--- the manager's list and the payment status (FR12, FR13)")
        check("a manager lists all orders, newest first", requests.get(f"{ORDER}/api/orders", headers=manager, timeout=10), 200,
              lambda r: [o["id"] for o in r.json()][:2] == [order_id + 1, order_id] and r.json()[1]["username"] == "customer1" and r.json()[0]["username"] == temp_user)
        check("a customer cannot list orders", requests.get(f"{ORDER}/api/orders", headers=customer, timeout=10), 403)
        url = f"{ORDER}/api/orders/{order_id}/payment-status"
        check("a manager marks the order as paid", requests.patch(url, json={"paymentStatus": "PAID"}, headers=manager, timeout=10), 200, lambda r: r.json()["paymentStatus"] == "PAID")
        check("...and the list shows it as paid", requests.get(f"{ORDER}/api/orders", headers=manager, timeout=10), 200, lambda r: r.json()[1]["paymentStatus"] == "PAID")
        check("a customer cannot change the status", requests.patch(url, json={"paymentStatus": "PENDING"}, headers=customer, timeout=10), 403)
        check("a status that is not PENDING or PAID", requests.patch(url, json={"paymentStatus": "FREE"}, headers=manager, timeout=10), 400)
        check("the status of an order that does not exist", requests.patch(f"{ORDER}/api/orders/999999999/payment-status", json={"paymentStatus": "PAID"}, headers=manager, timeout=10), 404)
        check("an unknown address", requests.get(f"{ORDER}/api/nothing", headers=manager, timeout=10), 404)
        check("a wrong method", requests.delete(f"{ORDER}/api/orders", headers=manager, timeout=10), 405)

        print("\n--- when book-service is down (not timed: the answer waits for the connection to fail)")
        book_process.terminate()
        book_process.wait(10)
        check("placing an order answers 503, it does not hang or crash", requests.post(f"{ORDER}/api/orders", json=body, headers=customer, timeout=15), 503, timed=False)
        check("...and listing orders still works", requests.get(f"{ORDER}/api/orders", headers=manager, timeout=10), 200, lambda r: len([o for o in r.json() if o["id"] > order_id + 1]) == 0)
        expect("order-service is still running", order_process.poll() is None)
    finally:
        print("\n--- cleaning up")
        try:
            clean_up(config, order_ids, taken, temp_user, processes, logs)
        finally:
            for process in processes:
                if process.poll() is None:
                    process.terminate()
            for process in processes:
                try:
                    process.wait(10)
                except subprocess.TimeoutExpired:
                    process.kill()
            time.sleep(0.5)
            still_open = [port for port in PORTS if port_is_open(port)]
            expect(f"no service is left running (ports still open: {still_open})", not still_open)

    passed = sum(results)
    print(f"\n{passed} of {len(results)} checks passed. Slowest timed request: {slowest:.0f} ms (limit {N1_LIMIT_MS} ms). Service logs: {logs}")
    print("ALL CHECKS PASSED" if passed == len(results) else "SOME CHECKS FAILED")
    return 0 if passed == len(results) else 1


def clean_up(config: Config, order_ids: list[int], taken: dict[str, int], temp_user: str, processes: list[subprocess.Popen], logs: Path) -> None:
    """Put the databases back as they were. Needs book-service, so it is started again if the check stopped it."""
    if taken:
        if not port_is_open(8082):
            processes.append(start("book-service-again", [sys.executable, "-m", "book_service"], SERVICES / "book-service", 8082, logs))
        for book_id, quantity in taken.items():
            requests.patch(f"{BOOK}/api/books/{book_id}/copies", json={"change": quantity}, headers={"X-Service-Key": config.service_key}, timeout=10).raise_for_status()
        print(f"gave back {sum(taken.values())} copies")
    connection = mysql.connector.connect(host=config.mysql_host, user=config.mysql_user, password=config.mysql_password, database=config.mysql_database)
    cursor = connection.cursor()
    for order_id in order_ids:
        cursor.execute("DELETE FROM orders WHERE id = %s", (order_id,))
        (config.bills_folder / f"bill-{order_id}.html").unlink(missing_ok=True)
    cursor.execute("DELETE FROM users WHERE username = %s", (temp_user,))
    connection.commit()
    connection.close()
    print(f"deleted {len(order_ids)} orders, their bills, and the temporary customer")


if __name__ == "__main__":
    sys.exit(main())
