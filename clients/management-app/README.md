# Management app

**Mooney's Manager**: the bookstore's desktop app for managers. Flutter (Dart), Windows.

Requirements covered: FR1, FR2, FR8, FR9, FR11–FR14, N2, N4, N5.

| Screen | What the manager does |
|---|---|
| Log in | Logs in. A customer account is refused: customers use the customer app |
| Orders tab | Sees every order, newest first, with how many wait for payment; filters Pending / Paid; marks an order as paid (with Undo) |
| An order | Opens its bill in the app; marks it paid, or back to pending; prints it (the saved HTML bill opens in the browser) |
| Books tab | Searches the catalog by title or author as they type |
| Add / edit book | Title, author, price, copies, its shelf, an optional cover image; each problem shown under its field |

Screenshots: [style guide](../../docs/02-design/style-guide.md#management-app-as-built-m4).

## Run

The three services must be running ([services](../../services/README.md)). Test account: `manager1` / `manager123`.

```bash
flutter run -d windows
```

Or, in VS Code: Run and Debug, "Management app", F5. Release builds are blocked on this machine (problem P-017); debug builds work.

## Test

```bash
flutter test
```

16 tests, no server needed: the book rules, and every screen driven the way a manager uses it with stand-in services, including one test in a 1024 x 700 window. Two more are skipped unless asked for:

| Command | Does |
|---|---|
| `set BOOKSTORE_LIVE=1 && flutter test test/live_services_test.dart` | The app's own service clients against the real running services. Changes nothing: it reads, and saves one book with the values it already has |
| `set BOOKSTORE_SCREENSHOTS=1 && flutter test test/screenshots_test.dart` | First, once: `python tools/screenshots/fetch_covers.py` in the repository root, for the real cover photos. Draws each screen with the real typefaces into `docs/02-design/ui/manager-*.png` |

## How it is built

| Folder | Holds |
|---|---|
| `lib/screens/` | The login screen, the home screen with its two tabs, the book form |
| `lib/api/` | `OrderApi`, the manager's calls to order-service |
| `lib/models/` | The book rules |
| `lib/main.dart` | Starts the app and gives every screen the session and the services |

The login form, the user and book clients, the session, the book and order data, the bill, and every widget come from the shared package [`../bookstore-ui`](../bookstore-ui/README.md), the same as in the customer app.

Class diagram and a description of every file: [class-diagrams.md](../../docs/02-design/class-diagrams.md#manager-app).

## Things worth knowing

- **One click to mark as paid**, on the row itself, and Undo in the message that follows. The order's own page also lets a mistake be put back to pending.
- **Changes are visible to customers at once.** A changed number of copies shows in the customers' search on their next search.
- **Print uses the saved bill**, the same file that was emailed, so what is posted to the customer is exactly what they received.
- **No plugins.** Printing opens the bill with Windows' own `start` command, so Windows Developer Mode is not needed.
