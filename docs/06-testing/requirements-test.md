# Requirements test report

> Status: **every requirement FR1–FR14 and N1–N5 has passing evidence, as of 2026-11-17** (issue #13). What could not be checked is listed at the end.

Each requirement is shown three ways, so that no single kind of test is trusted alone:

- **Automated**: tests that run with no server (`mvn package`, `python -m unittest`, `flutter test`). All 346 pass (counted again after the apps started the services themselves, 2026-11-20, E-052).
- **Live**: calls to the three real services running against the real MySQL and MongoDB: `services/order-service/manual_check.py` (41 checks, all passed on 2026-11-18) and the apps' own clients in `live_services_test.dart` (customer and management app, both passed on 2026-11-18).
- **Window**: the owner using the real app windows. The owner ran the customer app, the management app, and the account page and checkout on 2026-11-17 and reported that everything works.

## Test counts (all run on 2026-11-18)

| Part | Command | Tests | Result |
|---|---|---|---|
| user-service | `mvn package` | 26 | Pass |
| book-service | `python -m unittest discover -s tests -t .` | 76 | Pass, including 18 against the real MongoDB |
| order-service | `python -m unittest discover -s tests -t .` | 117 | Pass, including 10 against the real MySQL |
| Shared package | `flutter test` in `clients/bookstore-ui` | 46 | Pass |
| Customer app | `flutter test` | 47 | Pass |
| Management app | `flutter test` | 34 | Pass |
| **Total** | | **346** | **Pass** |

## Functional requirements

| | Requirement | Automated | Live | Window |
|---|---|---|---|---|
| FR1 | Log in with username and password; a session starts | user-service `loginReturnsATokenAndTheUser`, `loginWithAWrongPasswordIs401`, `anUnknownUserGetsTheSameMessageAsAWrongPassword`; customer app "a wrong password is said plainly…", "logging in opens the search screen" | Customer live check: wrong password refused, `customer1` logs in (219 ms). Manager live check: `manager1` logs in | Both apps |
| FR2 | Logged in until logout; every action tied to the session | user-service `afterLogoutTheTokenIsRefused`, `theSessionEndpointSaysWhoTheTokenBelongsTo`; customer app "when a service says the session has ended, the app goes back to log in" | Customer live check: logs out; an ended token sends the app back to log in | Both apps: Log out |
| FR3 | Create an account; password hashed (extra credit) | user-service `registeringCreatesAnAccountThatCanLogIn`, `registeringATakenUsernameIs409`, `registeringCreatesACustomerWithAHashedPassword`, the 5 `RegisterRequestTest`s; customer app "registering checks every field…" | `manual_check.py` registers its temporary customer and logs in with it | Customer app |
| FR4 | Search by keyword in title and author | book-service `test_search_matches_the_title`, `test_search_matches_the_author_and_ignores_case`, `test_special_characters_in_the_keyword_are_plain_text`; MongoDB `test_search_matches_title_or_author_ignoring_case` | Customer live check: "java" finds the three Java books (34 ms) | Customer app, as you type |
| FR5 | Results show at least title, author, price | book-service `test_search_results_show_title_author_and_price`; customer app screens test in the list view | Customer live check reads title, author, price of every book | Covers and list view |
| FR6 | Select one or more books | Customer app `order_draft_test.dart` (9); "a book is added, the order is placed…" | `manual_check.py`: an order with two books | Customer app |
| FR7 | Buy and/or rent in one transaction that creates an order | order-service `test_buying_and_renting_the_same_book_takes_two_copies`, `test_when_saving_fails_the_copies_are_given_back`, the 404/409 tests that save nothing; MongoDB `test_two_orders_at_once_cannot_both_take_the_last_copy` | `manual_check.py`: buy one and rent one; a missing book and a sold-out book are refused and every copy is given back | Customer app |
| FR8 | A bill with order ID, items, prices, total | order-service `test_placing_an_order_answers_with_the_order_and_its_bill`, `test_bill.py` (14); shared `order_test.dart` | `manual_check.py`: the bill's total is checked against a price worked out separately | The bill screen; the manager's order dialog |
| FR9 | The bill saved as an HTML file | order-service `test_the_bill_is_saved_as_an_html_file`, `test_a_bill_whose_file_was_deleted_is_made_again` | `manual_check.py`: the file exists and equals the bill returned; deleted, it is made again identical | Manager app: Print bill opens it in the browser |
| FR10 | The bill emailed (extra credit) | order-service `test_the_bill_is_emailed_to_the_customer`, `test_a_failed_email_does_not_fail_the_order`, `test_mailer.py` (5) | `email_check.py`: a real email accepted by Gmail (2026-11-16) | The owner saw it in the Gmail inbox |
| FR11 | A separate manager interface | Management app "a customer account is refused: this app is for managers"; customer app "a manager is refused: placing orders is for customers" | — (the role check is in each service, see N5) | Two separate apps |
| FR12 | The manager sees all orders | order-service `test_a_manager_sees_all_orders_newest_first`; management app screens tests | `manual_check.py`: newest first, both customers' orders | Management app |
| FR13 | The manager updates the payment status | order-service `test_a_manager_marks_an_order_as_paid`, `test_a_manager_can_put_an_order_back_to_pending`; management app "marking an order as paid changes it at once, and Undo puts it back" | `manual_check.py`: marked paid, and the list shows it | Management app |
| FR14 | The manager adds and updates books | book-service `test_a_manager_adds_a_book`, `test_a_manager_updates_the_number_of_copies`, `test_adding_a_book_checks_every_field`; management app `book_rules_test.dart` (6) and form tests | Manager live check: saves a book | Management app |

## Non-functional requirements

| | Requirement | Evidence |
|---|---|---|
| N1 | Endpoints answer in under 500 ms | `manual_check.py` times every order call from a cold start: slowest 147 ms (2026-11-17). Customer live check: login 219 ms, all books 70 ms, search 34 ms, place order 207 ms, my orders 64 ms, pay 44 ms. Manager live check (2026-11-17): login 187 ms, orders 22 ms, one order 17 ms. user-service and book-service were also timed in M3 (P-004, P-005) |
| N2 | The window never freezes; calls are asynchronous | Every service call in both apps is a `Future` awaited while a spinner shows (class diagram note). The screen tests drive each screen while requests run; buttons are disabled during a request. In the window, the owner reported no freezing. A service that is down answers within 8 s with a sentence, never a hang (`api_client_test.dart`: "a service that is too slow gives the same plain message instead of hanging") |
| N3 | Passwords stored with a strong one-way hash | user-service `registeringCreatesACustomerWithAHashedPassword`. In the real database on 2026-11-17: all 3 accounts are bcrypt hashes (`$2a$10$…`, 60 characters), checked by a script that printed only the first 7 characters of each |
| N4 | Every endpoint with user data needs a valid token | user-service `withoutATokenTheSessionEndpointIs401`; book-service `test_without_a_token_every_app_endpoint_is_401`, `test_an_ended_session_is_401`; order-service `test_without_a_token_every_endpoint_is_401` (all 7 endpoints), `test_an_ended_session_is_401`. Live: `manual_check.py` "no token" and "a token that is not a session" |
| N5 | Users see only their own data; roles cannot cross | order-service: a customer cannot list all orders, change a status, get, open, or pay someone else's order; a manager cannot order or use the checkout. book-service `test_a_customer_cannot_add_or_change_books`, `test_the_copies_endpoint_is_closed_to_the_apps`. Live: `manual_check.py` checks each of these with a second, temporary customer. Each app also refuses the other role at log in |

## Added beyond the PRD, also checked

| Feature | Automated | Live | Window |
|---|---|---|---|
| Account page (orders, rentals due back, profile, preferences) | order-service: 3 tests for `GET /api/orders/mine`; customer app `account_test.dart` (6) and 2 screen tests | `manual_check.py`: only the customer's own orders; managers refused | Tried by the owner |
| Pretend checkout | order-service: 5 tests for `POST /api/orders/{id}/pay`; customer app screen test | `manual_check.py`: pays, twice refused, someone else's refused, manager refused | Tried by the owner |

## Extra credit (course section 6)

The course document lists three extra-credit items, 1% each. All three are built (GitHub milestone "M6 - Extra Credit (course section 6)", issues #19, #20, #21). The "In the apps" column says where each one is; the owner has not yet tried reviews or the report in the app windows.

| Item | Automated | Live | In the apps |
|---|---|---|---|
| User profiles with order history (#19, built in M4) | order-service `test_a_customer_sees_only_their_own_orders_newest_first_with_items` and the other `GET /api/orders/mine` tests (one against the real MySQL); customer app `account_test.dart` (6), screen test "the account page shows the profile, the rentals due back, and the orders, and pays one" | `manual_check.py`: only the customer's own orders, managers refused. Customer live check: my orders 64 ms (2026-11-17) | Customer app: the name in the top bar opens "Your account" (profile, preferences, rentals due back, every order with its bill). Tried by the owner |
| Book reviews and ratings (#20) | book-service `test_reviews_api.py` (25: save, replace, the 1–5 and 1000-character rules, a manager refused, 401, 404, newest first, delete, ratings on search and get, rounding, `test_the_id_in_any_capitalisation_is_the_same_book_and_the_same_review`); `MongoReviewRepositoryTest` (8, real MongoDB: the unique index, one review per customer even when saved at the same moment, the rating aggregation); shared `review_test.dart`, `stars_test.dart`, the `reviews` group of `api_client_test.dart`; customer app `reviews` group in `screens_test.dart` (write, no stars chosen, the 1000 limit, emoji, Esc during a save, edit, delete with Undo, a failed load) | Customer live check (2026-11-18): a review saved in 15 ms, listed first, the book's `ratingCount` up by one, deleted again. The real `reviews` collection was left empty with its unique index | Customer app: stars on each card and in the list view; the book's detail panel has a Reviews section ("Your review" with Edit and Delete, then others). Screenshot `customer-reviews-light.png` |
| Sales report and analytics for managers (#21) | order-service: 15 API tests from `test_the_sales_report_of_all_orders` to `test_only_a_manager_sees_the_sales_report` (day edges, open periods, `top`, best-seller order including `test_best_sellers_with_the_same_copies_and_revenue_are_alphabetical_whatever_the_case`, an empty period, every validation message), and `test_list_between_includes_the_start_and_excludes_the_end_newest_first_with_items` against the real MySQL; management app `sales_report_test.dart` (7), five Reports screen tests, the 1024 x 700 test, and the username tests in `screens_test.dart` and `home_bar_test.dart` | Manager live check (2026-11-18): the all-time report in 15 ms counted exactly the 4 orders the order list showed, with 6 best sellers. `manual_check.py` 41 of 41 on the new code (slowest 88 ms), but it has no report check | Management app: the Reports tab (Today, Last 7 days, Last 30 days, This month, All time; four tiles; Sales by day; Best sellers; Orders in this period). Screenshots `manager-reports-light.png`, `manager-reports-dark.png` |

The test order and the review made by the live checks were removed afterwards.

## The release files, as a grader gets them

| Check | Where | Result |
|---|---|---|
| Every test suite (user-service, both Python services, the shared package, both apps) | GitHub's Windows machine, before building | Pass |
| Installer: silent install for the current user, every file, both Start menu entries, both apps open and keep running, clean uninstall | GitHub's Windows machine (`installer/test-installer.ps1`), in the build that published v1.0.0-beta.1 | Pass: all 19 checks; the apps opened windows titled "Bookstore" and "Bookstore Management"; installed size 64 MB |
| Server zip: unzipped into a new folder; `setup.cmd` passes all seven steps; the 41 service checks pass using the jar GitHub built (slowest 176 ms); `start-services.cmd` and `stop-services.cmd` work | Development computer, 2026-11-17 (with its existing `services/.env` copied in, so no new MySQL password was needed) | Pass |
| The zips contain no secrets (`services/.env`, `setup.local.sql`) | Server zip | None there |
| Both apps' live checks against the running services, again: customer login 201 ms, order 96 ms, pay 40 ms; manager orders 24 ms, one order 21 ms | Development computer, 2026-11-17 | Pass; the test order was removed afterwards |
| The installer on the development computer | Development computer | **Blocked by Smart App Control**, as is every unsigned program there (P-017) |
| **A second computer**: the published v1.0.0-beta.2, downloaded onto a new GitHub Windows machine that had never seen the project, following INSTALL.md (`.github/workflows/fresh-machine-test.yml`). Its Java was too old (17), and MySQL and MongoDB were installed but off; the test switched them on and put Java 21 first, which on a real PC `setup.cmd` does with winget | GitHub, 2026-11-17 | Pass. setup created the database, the account, and the data from nothing, and a second run changed nothing; all 41 service checks passed (slowest 99 ms); the services started; the installer installed both apps and both opened while the services ran. The first attempt failed only because the test's own step used Java 17; fixed in the test |
| **The same for v1.1.0** (reviews, ratings, sales report) | GitHub, 2026-11-18 | Pass. setup loaded the 27 books from nothing; all 41 service checks passed (slowest 87 ms); the installer installed both apps and both opened |
| **The same for v1.2.0** (81 books, demo customers, sales, reviews) | GitHub, 2026-11-18 | Pass on the second run. setup loaded the 81 books and the demo data (14 customers, 100 orders, 98 reviews) from nothing, and its second run kept them; all 41 service checks passed (slowest 104 ms); both apps installed and opened. The first run failed once: user-service did not start for the checks (P-018) |
| **The same for the final v1.0.0** (Mooney's, shelves, real covers) | GitHub, 2026-11-18 | Pass. setup loaded all 27 books from nothing, and its second run changed nothing; all 41 service checks passed (slowest 109 ms); both apps installed and opened, titled "Mooney's" and "Mooney's Manager" |

## Not checked

| What | Why | Plan |
|---|---|---|
| Screen readers (Windows Narrator) | Labels are in place, but no one has listened to them | Optional; not a PRD requirement |
| A color-blindness simulation of the screenshots | Not run. States are told by icons and words, never by color alone | Optional |
| Trackpad scrolling, and how the motion feels | Needs a person and real hardware | The owner, if wanted |
| The bill email in mail programs other than Gmail on the web | Only Gmail was tried | Optional |
| `setup.cmd` installing Java, Python, and MongoDB with winget, and a person typing the MySQL root password | The fresh-machine test did these steps itself (see above) | Optional |
| A person clicking through the installed release apps on a computer other than GitHub's | Smart App Control blocks them on the development computer (P-017) | The instructor, when grading |

## How to repeat this

1. Seed the data: `python database/seed.py` (repo root).
2. Run the automated tests (commands in the table at the top).
3. With ports 8081–8083 free: `python manual_check.py` in `services/order-service`. It starts and stops the services itself.
4. With the services running: `set BOOKSTORE_LIVE=1 && flutter test test/live_services_test.dart` in each app. The customer check places one real order; remove it afterwards.
