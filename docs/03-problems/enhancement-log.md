# Enhancement log

Improvements made **beyond what the requirements or the first design asked for**: what was added, why, and what it changed. Problems and their fixes are in the [problem log](problem-log.md); a fix that also left the project better than planned appears in both.

Each entry says whether the PRD required it. "No" means it was a choice, and could be removed without failing a requirement.

## Summary

| ID | Date | Enhancement | Area | Required by PRD? |
|---|---|---|---|---|
| E-001 | 2026-11-13 | Every design traces to a requirement | Docs | No |
| E-002 | 2026-11-13 | Placing an order reduces the available copies | Design | Implied |
| E-003 | 2026-11-13 | Books can have a cover image; a cover is generated when there is none | Apps, database | No |
| E-004 | 2026-11-13 | Cover grid with a list view, instead of only a table | Customer app | No (FR5 needs a clear list) |
| E-005 | 2026-11-13 | Search filters as you type | Customer app | No |
| E-006 | 2026-11-13 | Undo after adding a book; Esc and Ctrl+F shortcuts | Customer app | No |
| E-007 | 2026-11-13 | Light and dark mode | Both apps | No |
| E-008 | 2026-11-13 | Color-blind-safe states and checked contrast | Both apps | No |
| E-009 | 2026-11-13 | One shared UI package for both apps | Apps | No |
| E-010 | 2026-11-13 | Smooth mouse-wheel scrolling | Both apps | No |
| E-011 | 2026-11-13 | Typefaces bundled with the apps | Both apps | No |
| E-012 | 2026-11-13 | Memory mode: a service can run without its database | user-service | No |
| E-013 | 2026-11-13 | Login does not reveal which usernames exist | user-service | No |
| E-014 | 2026-11-13 | Services listen on both loopback addresses | user-service | No (helps N1) |
| E-015 | 2026-11-13 | Database connection pool | user-service | No (helps N1) |
| E-016 | 2026-11-13 | Start-up warm-up | user-service | No (helps N1) |
| E-017 | 2026-11-13 | A dedicated, limited MySQL account instead of root | Database | No |
| E-018 | 2026-11-13 | Request validation with messages that name the field | user-service | Partly (FR3 asks for a valid email) |
| E-019 | 2026-11-13 | Tests that call the real server over HTTP | user-service | No |
| E-020 | 2026-11-13 | Generated diagrams, checked after every export | Docs | No |
| E-021 | 2026-11-16 | The last copy of a book cannot be sold twice | book-service | No |
| E-022 | 2026-11-16 | A clear answer when another service is down | book-service | No |
| E-023 | 2026-11-16 | Search treats the keyword as plain text | book-service | No |
| E-024 | 2026-11-16 | Database tests on a separate, disposable database | book-service | No |
| E-025 | 2026-11-16 | An order is all or nothing across two services | order-service | Partly (the PRD asks for one transaction) |
| E-026 | 2026-11-16 | A lost bill file is made again | order-service | No |
| E-027 | 2026-11-16 | The bill email is sent in the background | order-service | No (helps N1) |
| E-028 | 2026-11-16 | Exact money | order-service | No |
| E-029 | 2026-11-16 | A repeatable check of the whole running system | order-service | No |
| E-030 | 2026-11-16 | A code review before each service is committed | Process | No |
| E-031 | 2026-11-17 | Search as you type, without stale results | Customer app | No (FR4 needs a search) |
| E-032 | 2026-11-17 | The app always shows the bill's prices, to the cent | Customer app | No |
| E-033 | 2026-11-17 | An ended session returns to log in, says why, and forgets the order | Customer app | Partly (N4) |
| E-034 | 2026-11-17 | The order survives a failure, and the message says what to do | Customer app | No |
| E-035 | 2026-11-17 | No plugins: the apps need no Developer Mode | Both apps | No |
| E-036 | 2026-11-17 | Screens tested as a customer uses them, in a small window too, and drawn to images | Customer app | No |
| E-037 | 2026-11-17 | The two apps share one log-in and one set of service clients | Both apps | Partly (N5) |
| E-038 | 2026-11-17 | Marking an order as paid takes one click, and can be undone | Management app | No (FR13 needs the update) |
| E-039 | 2026-11-17 | The manager can see and print any bill | Management app, order-service | No |
| E-040 | 2026-11-17 | The management app is tested the same way, in a small window too | Management app | No |
| E-041 | 2026-11-17 | An account page: profile, rentals due back, every order and its bill | Customer app, order-service | No (asked for by the owner) |
| E-042 | 2026-11-17 | A pretend checkout, with no card details | Customer app, order-service | No (asked for by the owner) |
| E-043 | 2026-11-17 | Each customer's preferences are remembered on the computer | Customer app | No (asked for by the owner) |
| E-044 | 2026-11-17 | Installable on a new computer with three double-clicks | Whole project | No (asked for by the owner) |
| E-045 | 2026-11-17 | Shelves: books by category, like a bookshop's sections | book-service, both apps | No (asked for by the owner) |
| E-046 | 2026-11-17 | Real cover photos, never an empty slot | Both apps, sample data | No (asked for by the owner) |
| E-047 | 2026-11-17 | The store has a name and a sign: Mooney's | Both apps, the bill, the installer | No (asked for by the owner) |
| E-048 | 2026-11-18 | Book reviews and ratings | book-service, customer app | No (extra credit, course section 6) |
| E-049 | 2026-11-18 | A sales report for managers: a period's orders, sales by day, best sellers | order-service, management app | No (extra credit, course section 6) |
| E-050 | 2026-11-18 | Built by several agents, with a separate review stage that tried to break the work | Process | No |

## Details

### E-001 — Every design traces to a requirement

Each service, table, endpoint, class, screen, and use case in the design documents names the requirement (FR or N number) it exists for.
**Why:** it shows nothing was built without a reason and nothing required was forgotten.
**Effect:** this is how the features the PRD does not ask for (reviews, order history) were found and removed.

### E-002 — Placing an order reduces the available copies

The PRD says the manager can update the number of copies, but not that ordering changes it. The order service now reduces each ordered book's copies, through an endpoint only it can call.
**Why:** without it, a book with one copy could be sold any number of times, and "available copies" would mean nothing.
**Where:** [api-design.md](../02-design/api-design.md) (`PATCH /api/books/{id}/copies`), architecture decision 5.

### E-003 — Cover images, with a generated fallback

A book has an optional `coverUrl`. With none, the app draws a cover from the title: a muted color that is always the same for that title, the title in a serif, and a sheen.
**Why:** the approved style makes book covers the only color in the interface, and the sample books have no images.
**Where:** `clients/bookstore-ui/lib/src/book_cover.dart`, [style-guide.md](../02-design/style-guide.md).

### E-004 — Cover grid with a list view

The wireframe showed search results as a table. The app shows a grid of covers and offers the table as a list view.
**Why:** browsing by cover is how people look for books; the list is faster for scanning prices. FR5 is met by both.

### E-005 — Search as you type

Results update with each keystroke instead of after pressing a Search button.
**Why:** fewer steps, and the heading always says how many books match (Nielsen 1: visibility of system status).

### E-006 — Undo and keyboard shortcuts

Adding a book shows a message with Undo. Esc closes the detail panel, then clears the search. Ctrl+F jumps to the search field.
**Why:** Nielsen 3 (user control and freedom) and 7 (efficiency of use).

### E-007 — Light and dark mode

Two palettes with the same structure; one button switches, with an animated transition.
**Why:** asked for by the project owner. Costs little because every color comes from one file.

### E-008 — Color-blind-safe states and checked contrast

No state is shown by color alone: availability, errors, and payment status always have an icon and a word. Every text color was measured against WCAG AA (4.5:1) in both modes.
**Why:** asked for by the project owner.
**Effect:** one color failed the first measurement (light-mode tertiary text, 4.05) and was darkened to 4.7 before it was ever used.

### E-009 — One shared UI package

Colors, type, spacing, motion, and the common widgets live in `clients/bookstore-ui`, used by both apps.
**Why:** two apps that must look identical should not each hold a copy of the look. A color changes in one place.

### E-010 — Smooth mouse-wheel scrolling

Flutter on desktop moves a page in steps per wheel notch. The apps animate to the new position instead.
**Why:** "as smooth as possible" was the brief.
**Not yet verified:** how it feels has to be judged by hand; a screenshot cannot show it.

### E-011 — Bundled typefaces

Inter and Source Serif 4 are shipped inside the app, with their licenses.
**Why:** the app looks the same on every machine, including the one it is demonstrated on. (Apple's SF Pro could not be used; see P-010.)

### E-012 — Memory mode

`STORAGE=memory` runs user-service with no database, using the two test accounts.
**Why:** the service could be built and tested before the MySQL database existed, and the apps can be developed without MySQL running.
**How:** the rules depend on repository interfaces; there is a MySQL version and an in-memory version of each.
**Effect:** all 26 tests run in about 3 seconds with no database.

### E-013 — Login does not reveal which usernames exist

A wrong password and an unknown username get the same message, and the service does the same amount of work for both, so the response time is the same too.
**Why:** otherwise someone could find valid usernames by trying names and watching the answers. Not required, but standard practice and nearly free.

### E-014 — Both loopback addresses

The service listens on `127.0.0.1` and `::1`.
**Why and effect:** see P-004. The first request by the name `localhost` went from about 2,100 ms to about 135 ms.

### E-015 — Database connection pool

Connections are borrowed from a pool (HikariCP) instead of opened per query.
**Why and effect:** see P-005. A session check went from about 75 ms to 7–19 ms. That call is made by the other two services on every request, so it speeds up the whole system.

### E-016 — Start-up warm-up

At start-up the service practises password hashing and sends itself one refused login.
**Why and effect:** see P-005. The first login after a cold start went from 509–539 ms to 102–255 ms.

### E-017 — A dedicated, limited MySQL account

The services log in as `bookstore_app`, which can only read and write the bookstore database. Its password is generated on the machine and kept out of git. The root password is typed once by its owner and never stored.
**Why:** least privilege. If the app's password leaked, only bookstore data would be exposed. It also meant the root password never had to be shared.
**Verified:** the account was confirmed unable to read another database.

### E-018 — Validation that names the field

A bad request is answered with what is wrong and where: "The password must be at least 8 characters long", not "Bad request".
**Why:** the app can show the message next to the field as it is (Nielsen 9: help users recover from errors).

### E-019 — Tests over real HTTP

Eleven of the 26 tests start the real server on a free port and call each endpoint the way the apps will, for success and for every error.
**Why:** unit tests alone would not catch a wrong status code, a missing header, or a route that is not registered.
**Limit found:** these tests still missed P-004 and P-005, which only showed when the packaged service was run by hand. See those entries.

### E-020 — Generated, checked diagrams

The draw.io files are produced by scripts, and every exported image is looked at before it is committed.
**Why:** diagrams stay consistent with each other and can be regenerated when the design changes.
**Effect:** about a dozen layout faults were caught this way before being committed (see P-011).
**Where:** the scripts are in `tools/diagrams`, with a README. One of them still has a known fault; see "Known gaps" in the problem log.

### E-021 — The last copy cannot be sold twice

Taking copies is done in one atomic MongoDB step: "reduce the copies, but only if enough remain". It is not "read the number, check it, write it back".
**Why:** with read-then-write, two orders arriving at the same moment could both read "1 copy" and both succeed.
**Verified:** a test fires 20 attempts at once at a book with one copy. Exactly one succeeds, and the book ends at 0, not below.

### E-022 — A clear answer when another service is down

book-service asks user-service who each token belongs to. If user-service does not answer within about two seconds, book-service replies `503` with "The login service is not answering. Please try again in a moment."
**Why:** the alternatives are a frozen app, or wrongly telling a logged-in user they are logged out. The same is done if MongoDB is down.
**Verified:** user-service was stopped while book-service ran; the search answered 503 in 2.0 seconds.

### E-023 — Search treats the keyword as plain text

The keyword is escaped before it is used in the database's pattern search.
**Why:** otherwise typing `(` would cause an error, and `.*` would match every book. It also closes a way to make the database do expensive work on purpose.
**Verified:** tests search for `(`, `[`, `.*`, `\`, and `c++`; the last finds "The C++ Programming Language".

### E-024 — Database tests on a disposable database

The tests of the MongoDB repository run against a real MongoDB, but in a database of their own (`bookstore_test`) that is emptied before each test and dropped at the end.
**Why:** testing against the real thing catches what a stand-in cannot, and the real `bookstore` data is never touched.

### E-025 — An order is all or nothing across two services

Placing an order changes two databases owned by two services: copies in MongoDB (book-service) and the order in MySQL. order-service takes the copies first, then saves the order in one transaction; if a later book is missing or sold out, or the save fails, it gives back every copy it took.
**Why:** a database transaction covers only one database. Without the give-back, a failed order would quietly lower the stock.
**Verified:** tests order a real book together with an unknown one, a sold-out one, and with a database that fails; each time no order exists and every copy is back. On the running services the same was checked against the real MongoDB.
**Limit:** see "Known gaps" in the problem log (an answer from book-service that is lost).
**Where:** `OrderService.place`, architecture decision 16.

### E-026 — A lost bill file is made again

A bill shows only what is saved with the order, and always says "Pending". So if the file is missing when someone opens the bill, order-service makes it again, identical, and saves it. An order also still succeeds if the file cannot be written at that moment.
**Why:** FR9 makes the file the required part of an order; a deleted or unwritable file should not mean a lost bill or a failed order.
**Verified:** a test and the running check delete the file, open the bill, and compare it with the original: the same, character for character.

### E-027 — The bill email is sent in the background

The email is handed to a background thread and the order is answered at once. A failed send is logged with the order number and never reaches the customer as an error.
**Why:** a mail server can take seconds, and N1 allows 500 ms. The design had already said the email would move after the response if it proved slow; it was built that way from the start rather than measured into it.
**Effect:** the response says `emailQueued` instead of `emailSent`, because delivery is not known when the answer is given.
**Verified:** a real order answered in 101 ms and Gmail accepted its bill afterwards (`email_check.py`). How the bill looks inside Gmail is still to be looked at (see "Known gaps").

### E-028 — Exact money

order-service keeps every amount as an exact decimal number, not as the approximate fractions (`float`) that JSON numbers become by default. A rent charge is rounded to the cent, half up.
**Why:** with approximate fractions, 10% of 35.55 or the sum of several prices can be a cent off, and a bill must add up.
**Verified:** tests for 35.55 (3.56), 35.54 (3.55), and a price that arrives from book-service as 40.1.

### E-029 — A repeatable check of the whole running system

`services/order-service/manual_check.py` starts all three services, calls every order endpoint for real with 33 checks that each state the expected result, times every call from a cold start, deletes what it created, stops the services, and confirms none is left running.
**Why:** P-004, P-005, and P-014 all came from the gap between "the tests pass" and "the running program works". A check that is kept can be run again before every release.
**Effect:** first order after a cold start 93 ms; other requests 6–44 ms; with book-service stopped, 503 in 2.0 seconds.

### E-030 — A code review before each service is committed

After its tests and the running check passed, order-service was reviewed as a separate step, looking for bugs, duplicated rules, wasted work, and anything that disagreed with the documents.
**Why and effect:** see P-015. Ten findings; five fixed before the first commit, the rest recorded as decisions or known gaps.

### E-031 — Search as you type, without stale results

The customer app asks book-service for matching books a quarter of a second after the customer stops typing, instead of after pressing a Search button. Each search is numbered, and an answer to an older search that arrives after a newer one has started is thrown away.
**Why:** fewer steps (Nielsen 7), and without the numbering a slow answer to "jav" could replace the results for "java".
**Effect:** on the running services a search answered in 11 ms, so results follow the typing.

### E-032 — The app always shows the bill's prices, to the cent

The rent price is worked out in whole cents and rounded half up, the same way order-service charges it, and amounts are shown with thousands separators like the bill ($12,345.60).
**Why:** a price on screen that differs by a cent from the bill looks like an error and is one.
**Verified:** the live check placed a real rental order; the total order-service charged equals the price the app showed.

### E-033 — An ended session returns to log in, says why, and forgets the order

If any service answers that the session is no longer valid, the app goes back to the login screen with "Your session has ended. Please log in again." and empties the order being prepared. A manager account logging in to the customer app is told to use the management app.
**Why:** the alternative is a screen full of errors, or the next person at the computer seeing someone else's order.
**Verified:** a screen test, and the live check against user-service with an invalid token.

### E-034 — The order survives a failure, and the message says what to do

If placing the order fails, the books stay in it exactly as chosen. A book that sold out in the meantime is named: '"Clean Code" is not available. Remove it from the order and try again. Nothing was charged.'
**Why:** engineering rule "the user's work survives a failure" (Nielsen 9).
**Verified:** a screen test.

### E-035 — No plugins: the apps need no Developer Mode

The apps talk to the services with Dart's own HTTP client, and show the bill with their own widgets, instead of plugins (an HTTP package, a web view, a browser launcher).
**Why:** Flutter plugins on Windows need Developer Mode, which is off on this machine, and every native part is one more thing Smart App Control can block (P-002, P-017).
**Effect:** the customer app has no dependencies beyond Flutter and the shared UI package.

### E-036 — Screens tested as a customer uses them, and drawn to images

Eleven tests drive the real screens with stand-in services: log in, a wrong password, a manager refused, registering, adding books, placing an order, a failed order, Undo, an ended session, and one test that goes through every screen in a 1024 x 700 window and fails if anything overflows. A separate test draws each screen with the real typefaces into the style guide.
**Why:** layout faults only show at certain sizes or with certain text, and this project's diagrams showed how easily they are missed (P-011).
**Effect:** these tests found seven faults before the first commit (see P-013).

### E-037 — The two apps share one log-in and one set of service clients

The log-in form, the service clients, the session, and the book and order data were moved from the customer app into the shared package, and both apps use them. Each app passes the one role it lets in and the sentence that turns the other role away.
**Why:** two copies of the same login or the same bill would drift apart; the PRD's N5 asks for one consistent interface.
**Effect:** the management app needed no client code of its own for logging in or for books, only `OrderApi`. The tests of the moved code moved with it: 18 in the shared package, all passing.

### E-038 — Marking an order as paid takes one click, and can be undone

"Mark as paid" is on each pending row of the orders list, and the message that follows offers Undo. The list shows how many orders wait for payment, and filters All / Pending / Paid with a count on each. An order can also be put back to pending from its own page.
**Why:** marking payment (FR13) is the manager's most frequent job; one click with Undo is quicker than a confirmation dialog and as safe (Nielsen 3 and 7).
**Verified:** screen tests for marking, Undo, and the filter counts.

### E-039 — The manager can see and print any bill

An order opens its bill in the app, drawn by the same `BillView` the customer sees; Print opens the saved HTML bill, the same one that was emailed, in the browser. This needed one new endpoint, `GET /api/orders/{id}`, with the same rule as the bill: the customer who placed it, or a manager.
**Why:** a manager answering a customer's question needs to see what the customer saw.
**Verified:** four new order-service tests (manager, owner, another customer refused, unknown order); the app's live check read order 1050 from the running service in 17 ms.

### E-040 — The management app is tested the same way, in a small window too

Nine screen tests drive the management app with stand-in services, including one in a 1024 x 700 window that fails on any overflow; six book-rule tests; a live check of its clients against the running services; and drawn screenshots of each screen.
**Effect:** the small-window test found an 84-pixel overflow in the orders row before anyone saw it (P-013).

### E-041 — An account page: profile, rentals due back, every order and its bill

The customer's name in the top bar opens "Your account": who they are and where bills are emailed; each rented book with "Due back in 7 days" or "Was due back 2 days ago" (with a warning icon, not color alone); and every order, newest first, with its status and its bill. This needed `GET /api/orders/mine` in order-service, which reads one customer's orders in two queries, however many there are.
**Why:** the owner asked for a place to see history and orders. The PRD gives the customer no way to see an order again after leaving the bill screen.
**Verified:** three new API tests, one against the real MySQL; on the running service the list answered in 64 ms.

### E-042 — A pretend checkout, with no card details

"Pay now" on the bill, and "Pay" on each pending order of the account page, open a dialog with the total, a note that this is a demonstration and nothing is charged, and one button. Paying calls `POST /api/orders/{id}/pay`, which marks the customer's own pending order as paid; paying twice is refused (409).
**Why:** the owner asked for a way to complete payment. Asking for a card number would collect sensitive data the project has no business holding, so none is asked for, sent, or kept. The manager's FR13 controls are unchanged.
**Verified:** five new API tests (pay, twice, someone else's, a manager, unknown), two screen tests; on the running service paying answered in 44 ms and a second attempt was refused.

### E-043 — Each customer's preferences are remembered on the computer

Dark mode, and whether search opens as covers or a list, are saved per username in `%APPDATA%\CSCE310 Bookstore\preferences.json`, and applied at log in. The top-bar buttons and the account page's switches change the same setting. A missing or damaged file falls back to the defaults.
**Why:** the owner asked for preferences. They are only about how the app looks on this computer, so they stay on it and need no service.
**Verified:** five tests (kept per customer, damaged file, logged out, no file, and the screen test that logs out and in again).

### E-044 — Installable on a new computer with three double-clicks

`setup.cmd` checks every part, installs Java, Python, and MongoDB with winget when missing, creates the database with a limited account, loads the test data only if it is not there, and says in a sentence what to fix if something is wrong; it can be run again safely. `start-services.cmd` and `stop-services.cmd` start and stop the three services. The apps come as an installer that needs no administrator rights, built in release mode by GitHub Actions on each version tag, after every test passes there.
**Why:** the owner asked that whoever grades the project can install it without asking anything. The only question left is the grader's own MySQL root password, which only MySQL may see.
**Verified on the development computer:** setup.cmd passed all seven steps without a question, kept the existing settings and data, and start and stop worked, including starting twice. The GitHub build: see the release's run.

### E-045 — Shelves: books by category, like a bookshop's sections

Every book is on one of five shelves: Fiction, Nonfiction, Kids, Science, Technology. The customer app shows them as a row of tabs under the sign (All, then each shelf); the chosen tab is bold and underlined, not only colored, and works from the keyboard. A search stays on the chosen shelf, and when it finds nothing there it offers to search every shelf. The manager chooses a shelf when adding or editing a book, and sees each book's shelf in the list. book-service filters by it (`?category=`) and refuses an unknown one.
**Why:** the owner liked how a bookshop website shows its categories. 12 general books were added so no shelf is empty.
**Verified:** 6 new book-service tests (one against the real MongoDB), 3 shared and 2 app tests; on the running services the Fiction shelf answered in 25 ms.

### E-046 — Real cover photos, never an empty slot

Each book links to its real cover on Open Library. A cover shows the drawn cover first and fades the photo in once it has arrived, so a slot is never empty; without internet the drawn cover simply stays. Every photo was checked by eye on a contact sheet for the right title and an English edition (six were replaced, P-013).
**Why:** the owner liked real photos. Linking instead of storing keeps publishers' artwork out of the public repository.
**Effect:** the screenshots in the style guide show the real covers.

### E-047 — The store has a name and a sign: Mooney's

Gold capitals on deep green, drawn by our own widget (`MooneysSign`), inspired by the bookshop in the series *You*: in the top bar of both apps, large on the login screens, in the window titles, on the bill and the email subject, and in the installer and Start menu. It looks the same in light and dark mode, like a painted sign, and is the one colored thing besides the covers, so the approved neutral style holds.
**Why:** the owner wanted the store's logo shown off, as a bookshop website does.

### E-048 — Book reviews and ratings

A logged-in customer gives a book 1 to 5 whole stars and, if they want, up to 1000 characters of words. Each customer has one review per book, which they can edit or delete; a manager cannot write one (403). book-service has three new endpoints: `GET /api/books/{id}/reviews` (newest first), `PUT /api/books/{id}/reviews/mine`, and `DELETE /api/books/{id}/reviews/mine`. Reviews are in the MongoDB collection `reviews`, with a unique index `one_review_per_customer_per_book` on (bookId, userId). A book's `ratingAverage` (rounded half up to one decimal) and `ratingCount` are worked out from the reviews, in one aggregation per search, and never stored on the book, so they cannot drift from the reviews. In the customer app, each card shows one star with the average and the count, the list view has a rating column, and the detail panel has a Reviews section: "Your review" first with Edit and Delete (Delete offers Undo), then everyone else's. Stars are filled, half, or outlined, so they are told apart by shape, not color, and are read out in words.
**Why:** extra credit in the course document, section 6 (issue #20). Any customer may review, not only one who bought the book: checking for a purchase would make book-service call order-service, which already calls book-service. There is no moderation by managers; that was left out on purpose. Both are listed under "Known gaps" in the problem log.
**Verified:** `test_reviews_api.py` (25 API tests), 9 tests against the real MongoDB (the unique index, a second save that replaces, saves at the same moment, the rating aggregation, an id in capitals), shared `review_test.dart`, `stars_test.dart`, and the review tests in `api_client_test.dart`, and the customer app's `reviews` screen tests. On the running services, after restarting them on the new code: a review was saved in 15 ms, listed first, the book's `ratingCount` went up by one, and it was deleted again. The real `reviews` collection was left empty, with the unique index present. Screenshot: `docs/02-design/ui/customer-reviews-light.png`.

### E-049 — A sales report for managers

The management app has a third tab, Reports. The manager picks Today, Last 7 days, Last 30 days (the default), This month, or All time and sees four tiles (Orders, Revenue, Books sold, Books rented), a Sales by day bar chart with the amount over each bar when there is room, the Best sellers table, and the Orders in this period. The report is asked for when the tab opens and again each time the manager comes back to it, so an order just marked as paid is counted. It comes from one new order-service endpoint, `GET /api/reports/sales?from=&to=&top=`, for managers only: dates are `YYYY-MM-DD` and include both ends, `top` is 1 to 50 (default 10). The report is added up in Python, in exact decimals, from the orders of the period; best sellers are grouped by book id and ordered by copies, then revenue, then title regardless of case.
**Why:** extra credit in the course document, section 6 (issue #21). Adding up in Python is simple and fast enough at this scale; a database query would be the next step if the orders grew to many thousands.
**Verified:** 15 order-service API tests (the full report, the first and last second of a day, open-ended periods, the last possible date, `top`, the best-seller order, an empty period, every validation message, 401 and 403) and one against the real MySQL; the management app's `sales_report_test.dart` (7) and five Reports screen tests, with the 1024 x 700 test opening the tab too. On the running services, the all-time report answered in 15 ms and counted exactly the 4 orders the order list showed, with 6 best sellers. Screenshots: `manager-reports-light.png` and `manager-reports-dark.png` in `docs/02-design/ui`.
**Not judged:** how the bars' tooltips feel on hover, and sideways scrolling of the chart, cannot be seen in a screenshot.

### E-050 — Built by several agents, with a separate review stage

At the owner's request ("ultracode"), E-048 and E-049 were built by a multi-agent workflow. Four builders each worked in their own folders (book-service, order-service, the customer app with the shared package, the management app), test first. Then, for each area, an independent reviewer that had not written the code tried to break it, and wrote down for each finding how it had tried to prove it wrong. A fixer then fixed the confirmed findings, each with a test. Last, the lead checked every test suite, looked at the screenshots, and checked the work on the running services.
**Why:** P-015 showed that code which passes its own tests can still be wrong around them. A reviewer whose job is to break the code, and who did not write it, looks where the builder did not.
**Effect:** five findings in the four areas, all fixed before anything was committed (P-013): a book id in capital letters that let one customer review a book twice and hid those reviews from the rating; best sellers sorted with capitals first; a review dialog that could be closed during a save; a character count that disagreed with the service for emoji; and a top-bar fix that only worked for short usernames. The first could not have been found by the tests as written: the stand-in database was stricter than MongoDB. Its new test passed while the bug was still there, until the stand-in ids were given letters (P-015's lesson again).
**Then:** 333 tests pass, `manual_check.py` passed 41 of 41 (slowest 88 ms), and both apps' live checks passed.
