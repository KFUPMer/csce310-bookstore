# Phase 2 — Class diagrams

> Status: **draft**. To be finalized in milestone M2.

The two desktop apps are separate Flutter programs, written in Dart. Both are built the same way, in three layers:

| Layer | Color in the diagrams | What it does |
|---|---|---|
| Screens | Blue | One widget per screen; shows data, reacts to buttons, and keeps the screen's own state (loading, error, selection) |
| Service calls (`...Api`) | Green | One class per web service; sends HTTP requests with the session token |
| Data | Yellow | Plain objects such as `Book` and `Order`, built from the JSON the services return |

Every `...Api` class extends `ApiClient`. All of its methods are `async` and return a `Future`: the screen awaits the answer and shows a loading state meanwhile, so the window never freezes (N2). `ApiClient` also attaches the session token to every request (N4).

## Customer app

![Customer app class diagram](diagrams/class-customer-app.png)

Source: [diagrams/class-customer-app.drawio](diagrams/class-customer-app.drawio)

| Class | Purpose | Requirements |
|---|---|---|
| `LoginScreen` | Log in | FR1 |
| `RegisterScreen` | Create an account | FR3 |
| `SearchScreen` | Search by keyword, show title/author/price, add books to the order, log out | FR2, FR4, FR5, FR6 |
| `OrderScreen` | Review the selected books, choose buy or rent for each, place the order | FR6, FR7 |
| `BillScreen` | Show the bill returned for the order | FR8 |
| `OrderDraft` | The order being prepared, shared by the search and order screens | FR6 |
| `UserApi`, `BookApi`, `OrderApi` | Calls to user-service, book-service, order-service | N2, N4 |
| `Book`, `OrderItem`, `Order`, `ItemType` | Data; `OrderItem` works out the charge (10% when rented) and the rent due date (7 days) | FR7 |

## Manager app

![Manager app class diagram](diagrams/class-manager-app.png)

Source: [diagrams/class-manager-app.drawio](diagrams/class-manager-app.drawio)

| Class | Purpose | Requirements |
|---|---|---|
| `LoginScreen` | Log in; refuses anyone who is not a manager | FR1, FR11, N5 |
| `OrdersScreen` | List all orders, mark an order as paid, view its bill | FR12, FR13 |
| `BooksScreen` | Search books, open the add or edit dialog | FR14 |
| `BookFormDialog` | Add a new book or edit an existing one | FR14 |
| `UserApi`, `OrderApi`, `BookApi` | Calls to user-service, order-service, book-service | N2, N4 |
| `Order`, `Book`, `PaymentStatus` | Data | FR12–FR14 |

## Shared UI package

Everything both apps have in common: the colors, typefaces, spacing, motion, and the reusable widgets. Explained in the [style guide](style-guide.md).

![Shared UI package class diagram](diagrams/class-bookstore-ui.png)

Source: [diagrams/class-bookstore-ui.drawio](diagrams/class-bookstore-ui.drawio)

## File map

Every source file that exists so far, and the classes in it. Updated in the same commit as the code ([engineering rules](engineering-rules.md)).

### clients/bookstore-ui

| File | Classes | Purpose |
|---|---|---|
| `lib/bookstore_ui.dart` | — | Exports everything below |
| `lib/src/tokens.dart` | `BookstoreColors`, `Space`, `Radii`, `Motion`, `Fonts` | The design values, in one place |
| `lib/src/theme.dart` | `buildBookstoreTheme()` | Builds the light or dark theme from the tokens |
| `lib/src/glass.dart` | `Glass` | Translucent blurred panel |
| `lib/src/book_cover.dart` | `BookCover` | A book cover; draws one from the title when there is no image |
| `lib/src/app_button.dart` | `AppButton`, `AppButtonStyle`, `AppIconButton` | Buttons with hover, press, focus, and loading states |
| `lib/src/smooth_scroll.dart` | `SmoothScroll` | Animated mouse-wheel scrolling |
| `lib/src/status_chip.dart` | `StatusChip` | A state shown as an icon and a word |
| `test/bookstore_ui_test.dart` | — | Tests that a title always gets the same cover color |

### clients/customer-app

| File | Classes | Purpose |
|---|---|---|
| `lib/main.dart` | `CustomerApp` | Starts the app, holds light or dark mode |
| `lib/models/book.dart` | `Book`, `ItemType`, `money()` | A book, with its rent price (10%) |
| `lib/screens/search_screen.dart` | `SearchScreen`, and its private parts: `_Heading`, `_SearchField`, `_Availability`, `_BookCard`, `_BookRow`, `_DetailPanel`, `_EmptyState`, `_OrderLine` | Search and browse books, add them to the order |
| `lib/preview/mock_books.dart` | `mockBooks` | Sample data for the style preview. **Removed in M4** |
| `test/book_test.dart` | — | Tests the rent price, availability, and reading a book from JSON |

Private classes (names starting with `_`) are pieces of one screen and are used nowhere else, so they are listed here and not drawn as separate boxes.

Not built yet, and so still only in the diagram above: `LoginScreen`, `RegisterScreen`, `OrderScreen`, `BillScreen`, `OrderDraft`, the `...Api` classes, `Session`, `Order`, `OrderItem`. In the preview, the order being prepared is kept inside `SearchScreen`; it moves to `OrderDraft` in M4.

### clients/management-app

Still the empty Flutter starter project. Built in M4.

## Backend services

The class diagram of the three backend services is in [uml-diagrams.md](uml-diagrams.md), together with the other UML diagram types.
