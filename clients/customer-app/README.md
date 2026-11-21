# Customer app

**Mooney's**: the bookstore's desktop app for customers. Flutter (Dart), Windows.

Requirements covered: FR1–FR8 and FR10 (shows that the bill is emailed), FR3 (extra credit), N2, N4, N5, and two of the course's section-6 extra-credit items: profiles with order history (the account page) and book reviews and ratings.

| Screen | What the customer does |
|---|---|
| Log in | Logs in. A manager account is refused: managers use the management app |
| Create an account | Username, email, password; each problem is shown under its field before anything is sent |
| Search | Searches by title or author as they type; picks a shelf (Fiction, Nonfiction, Kids, Science, Technology); sees the real covers or a list with title, author, price; opens a book; buys or rents it. Each book shows its stars and number of reviews (4.3 (12)) |
| Book detail: Reviews | Under Buy and Rent: the rating, "Your review" first with Edit and Delete (Delete has Undo), then the other customers' reviews, newest first. A book with none says "No reviews yet. Be the first." |
| Write a review | 1 to 5 stars (mouse or keyboard) and optional words, up to 1000 characters with a count; "Choose a rating from 1 to 5 stars" if no stars are chosen. It cannot be closed while it is saving |
| Your order | Switches each book between buy and rent, removes books (with Undo), sees the total, places the order |
| Bill | Sees the bill of the order just placed, and that a copy is being emailed; can pay at once |
| Pay | The pretend checkout: shows the total, says nothing is charged, marks the order paid. No card details |
| Your account | Profile; preferences (dark mode, covers or list) remembered on this computer; rented books and when each is due back; every order with its bill, and Pay for a pending one |

The account page and the pretend checkout were asked for by the owner and go beyond the PRD, which leaves payment to the manager (FR13).

Screenshots: [style guide](../../docs/02-design/style-guide.md#customer-app-as-built-m4).

## Run

The three services must be running ([services](../../services/README.md)). Test accounts: `customer1` / `customer123`.

```bash
flutter run -d windows
```

Or, in VS Code: Run and Debug, "Customer app", F5.

**A release build is blocked on this machine** by Windows Smart App Control (problem P-017): it stops Flutter's release compiler. Debug builds work.

## Test

```bash
flutter test
```

47 tests, no server needed: the rules (the order draft, the account rules, rentals and due dates, preferences), writing, editing, and deleting reviews, and every screen driven the way a customer uses it, with stand-in services. One of them checks that every screen fits a 1024 x 700 window. The shared service client and data have their own tests in `../bookstore-ui`.

Two more are skipped unless asked for:

| Command | Does |
|---|---|
| `set BOOKSTORE_LIVE=1 && flutter test test/live_services_test.dart` | The app's own service clients against the three real running services: log in, search, write a review and see it in the rating, delete it again, place a real order, find it under "my orders", pay it (remove the order afterwards) |
| `set BOOKSTORE_SCREENSHOTS=1 && flutter test test/screenshots_test.dart` | First, once: `python tools/screenshots/fetch_covers.py` in the repository root, for the real cover photos. Draws each screen with the real typefaces into `docs/02-design/ui/customer-*.png` |

## How it is built

| Folder | Holds |
|---|---|
| `lib/screens/` | One file per screen. What is shown, and the screen's own state (loading, error). `review_dialog.dart` is the dialog to write or edit a review; the Reviews section is part of `search_screen.dart` |
| `lib/api/` | `OrderApi`, the customer's calls to order-service |
| `lib/models/` | The rules that need no screen: the order draft, the account rules, rentals due back, preferences |
| `lib/main.dart` | Starts the app and gives every screen the session, the order draft, the preferences, and the services |

The log-in form, the user and book clients (including the review calls), `ApiClient`, the session, the book, review, and order data, and everything visual (buttons, fields, the bill, the toast, the stars) live in the shared package [`../bookstore-ui`](../bookstore-ui/README.md), used by both apps.

Class diagram and a description of every file: [class-diagrams.md](../../docs/02-design/class-diagrams.md#customer-app).

## Things worth knowing

- **The window never waits (N2).** Every call to a service is awaited while the screen shows a spinner; buttons are disabled while their request runs, so nothing is sent twice.
- **Every failure is a sentence.** A service that is down gives "The book catalog is not answering. Please try again in a moment." within 8 seconds, never a frozen window or a raw error.
- **The order survives a failure.** If placing the order fails, the books stay in it, and the message says which book is the problem.
- **When the session ends** (logout, or a service answers 401), the app returns to the login screen, says why, and forgets the order being prepared.
- **Prices are the bill's prices.** The rent price is worked out in whole cents, rounded half up, exactly as order-service charges it.
- **Preferences** are kept in `%APPDATA%\CSCE310 Bookstore\preferences.json`, per username. Nothing secret is in it. If it cannot be read or written, the settings still work until the app closes.
- **No plugins.** The app uses Flutter and Dart's own HTTP client only, so Windows Developer Mode is not needed.
