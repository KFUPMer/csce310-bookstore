# Problem log

Every problem that cost real time or changed a decision gets an entry here. The goal is to show how the project actually went, not only the result.

Much of this project was built with an AI coding assistant (Claude). Its mistakes and dead ends are logged here like anyone else's, marked **Who: assistant**. Improvements that go beyond the requirements are in the [enhancement log](enhancement-log.md).

## Index

| ID | Problem | Who | Status |
|---|---|---|---|
| P-001 | Backend designed on the wrong technology | Assistant | Solved |
| P-002 | First Flutter build blocked by Windows security | Environment | Solved |
| P-003 | MongoDB shell blocked by Windows security | Environment | Worked around |
| P-004 | First request to user-service took over 2 seconds | Assistant | Solved |
| P-005 | Login too close to the 500 ms limit against the real database | Assistant | Solved |
| P-006 | Requirements and deadlines were guessed before the PRD arrived | Assistant | Solved |
| P-007 | Bundled fonts did not appear in the app | Assistant | Solved |
| P-008 | A documentation update failed and a commit silently did not happen | Assistant | Solved |
| P-009 | A hand-written placeholder was used where a real bcrypt hash was needed | Assistant | Solved before it ran |
| P-010 | The requested typeface (SF Pro) could not be used | Licensing | Worked around |
| P-011 | Diagram layout faults, and deleted diagrams coming back | Assistant | Solved |
| P-012 | Maven was not available from the package manager | Environment | Solved |
| P-013 | Small things that went wrong | Mixed | Solved |
| P-014 | A manual check failed and left a service running | Assistant | Solved |
| P-015 | order-service passed all its tests with faults a review then found | Assistant | Solved, with three limits left open |
| P-016 | The first real bill email arrived with its layout broken | Assistant | Solved |
| P-017 | Release builds of the apps are blocked by Windows security | Environment | Solved: built and tested on GitHub's Windows machine |

## How to add an entry

Copy the template, give it the next number, and link the GitHub issue and the commit or patch version that fixed it.

```markdown
## P-000 — Short title

- **Date found:** YYYY-MM-DD
- **Phase / milestone:** e.g. M3 Backend
- **Issue:** #number
- **Status:** Open | Solved | Worked around

**What happened**
What we saw, and what we expected instead.

**Cause**
What was actually wrong (once known).

**What we tried**
1. First attempt — result
2. Second attempt — result

**Solution**
What fixed it. Fixed in version vX.Y.Z (commit abc1234).

**Lesson**
What we do differently from now on.
```

---

## Entries

## P-001 — Backend designed on the wrong technology

- **Date found:** 2026-11-13
- **Phase / milestone:** M1 Idea & Requirements
- **Issue:** —
- **Status:** Solved

**What happened**
The first design used Spring Boot (Java) for all three backend services. It was written from the PRD's introduction, which says the services are "built with Java or Python Flask", before section 4 (non-functional requirements) had been read.

**Cause**
Section 4.1 fixes the technology of each service: user services in Java HttpServer, book services in Python Flask, order and billing services in Python Flask. Spring Boot is not one of the options, and two of the three services cannot be Java at all.

**What we tried**
1. Checked whether "Java everywhere" could still satisfy the PRD — it cannot; 4.1 is explicit per service.

**Solution**
Changed the stack in every document and in the architecture diagram: user-service → Java HttpServer, book-service and order-service → Python Flask, clients stay JavaFX (which also earns +2%). `catalog-service` was renamed `book-service` to match the PRD's wording. No code existed yet, so nothing had to be rewritten.

**Lesson**
Read the whole requirements document, including the non-functional part, before choosing technology. Caught in M1, this cost one documentation update; caught in M3 it would have cost a rewrite of the backend.

## P-002 — First Flutter build blocked by Windows security

- **Date found:** 2026-11-13
- **Phase / milestone:** M4 Desktop Clients (setup, done early)
- **Issue:** #18
- **Status:** Solved

**What happened**
The first `flutter build windows` of customer-app failed with "An Application Control policy or security policy has blocked execution". The blocked program was `impellerc.exe`, the shader compiler inside the Flutter SDK that had just been downloaded.

**Cause**
Windows checks a newly downloaded program the first time it runs and can block that first run. It was not a problem in the project: the starter app had not been changed.

**What we tried**
1. Built management-app straight after: it succeeded, using the same tool.
2. Built customer-app again: it succeeded.

**Solution**
Run the build again. No security setting was changed.

**Lesson**
On a freshly installed toolchain, a first-run failure that mentions a security policy is worth one retry before looking for a fault in the code.

## P-003 — MongoDB shell blocked by Windows security

- **Date found:** 2026-11-13
- **Phase / milestone:** M3 Backend Services (setup)
- **Issue:** #7
- **Status:** Worked around

**What happened**
After installing MongoDB Shell, running `mongosh` failed with "An Application Control policy has blocked this file". MongoDB Server itself installed and runs normally.

**Cause**
Windows **Smart App Control** is turned on on this machine. It blocks programs that are not digitally signed and that it does not recognize, and `mongosh.exe` is not signed (checked: its signature status is "NotSigned"). This is also what caused P-002. Unlike P-002, a second try did not help here.

**What we tried**
1. Ran `mongosh` after the install: blocked.
2. Checked whether the server was affected: it was not; the `MongoDB` service is running on port 27017.

**Solution**
The shell is only a convenience for looking at data by hand, so it is not needed. The seed script and the services use the Python driver (`pymongo`), which works: the 15 books were loaded and searched through it. No security setting was changed.

**Why it was not switched off**
Smart App Control can be turned off in Windows Security, but Windows does not allow turning it back on without reinstalling Windows. That is too high a price for an optional tool.

**Lesson**
Depend on as few tools as possible. The project needs the database server and a driver; a separate shell is optional, and MongoDB Compass (a graphical viewer) is an alternative if looking at the data by hand becomes necessary.

## P-004 — First request to user-service took over 2 seconds

- **Date found:** 2026-11-13
- **Phase / milestone:** M3 Backend Services
- **Issue:** #8
- **Status:** Solved

**What happened**
All tests passed, but when the packaged service was started and called for real, the first login took about 2,500 ms. Requirement N1 allows 500 ms. Later requests took under 100 ms.

**Cause**
The server was listening on `127.0.0.1` (IPv4) only. The name `localhost` can also mean `::1` (IPv6), and Windows tries IPv6 first. The client waited about two seconds for that attempt to fail before trying IPv4. The tests did not show it because Java's own client goes straight to IPv4.

**What we tried**
1. Timed the same request by address: `127.0.0.1` took 95 ms, `localhost` took 2,126 ms. That confirmed the cause.
2. Considered telling every client to use `127.0.0.1`: it works, but it is a trap for anyone who types `localhost`.

**Solution**
The server now listens on both `127.0.0.1` and `::1` (two listeners sharing the same handlers). After the fix: `localhost` 58–135 ms, `127.0.0.1` 58 ms, `::1` 57 ms. The service is still not reachable from other machines.

**Lesson**
Passing tests are not the same as working. Start the real program and call it the way a client will, and measure. The Flask services must listen on both addresses too.

## P-005 — Login too close to the 500 ms limit against the real database

- **Date found:** 2026-11-13
- **Phase / milestone:** M3 Backend Services
- **Issue:** #8
- **Status:** Solved

**What happened**
In memory mode every request took under 150 ms. Against the real MySQL database, logins took 290–375 ms and the first login after start-up took 539 ms. N1 allows 500 ms. Session checks, which the other two services will make on every request, took about 75 ms.

**Cause**
Three separate things, found one at a time by measuring:

1. The Python seed script hashed passwords with bcrypt cost 12; the Java service uses cost 10. Cost 12 is four times slower to check.
2. Every query opened a new database connection (about 35 ms each), and a login needs two queries.
3. Java runs code slowly the first few times. The first request paid for that in the hashing, database, HTTP, and JSON code all at once.

**What we tried**
1. Seed script changed to cost 10: logins dropped to about 200 ms, first login still 539 ms.
2. Connection pool (HikariCP): session checks dropped from about 75 ms to 7–19 ms, first login 509 ms.
3. Practice hashing at start-up: first login 430–470 ms. Under the limit, but too close.
4. A practice login against the database at start-up: first login 258–495 ms. Better on average, still not reliable.
5. One real request from the service to itself at start-up: first login 102–255 ms over four cold starts.

**Solution**
All of the above together: the same bcrypt cost on both sides, a connection pool, and a warm-up at start-up (`PasswordHasher.warmUp`, `UserServer.warmUp`, `UserServer.warmUpOverHttp`). The warm-up logs in as a user that does not exist, so it changes nothing.

**Lesson**
Test against the real database, not only the in-memory one, and measure from a cold start, because that is what a demo is. A number that passes with no margin is not a pass. Each fix was measured before the next was tried, which showed that no single change was enough.

## P-006 — Requirements and deadlines were guessed before the PRD arrived

- **Date found:** 2026-11-13
- **Phase / milestone:** M1 Idea & Requirements
- **Who:** assistant
- **Status:** Solved

**What happened**
The repository was set up from a two-line description of the project. To fill it, the assistant invented a set of requirements (categories, reviews, order history, shipping statuses, a "staff" role, login by email) and a five-week schedule. When the PRD arrived it contradicted most of them.

**Cause**
Starting the design before having the requirements document, and writing guesses in the same confident form as facts.

**Solution**
Everything was rewritten from the PRD (FR1–FR14, then N1–N5), the invented features were removed and listed as removed, and the schedule was redone for the real deadline of 4 December. P-001 is the largest single consequence of this.

**Lesson**
Ask for the requirements document first. When something has to be assumed, label it as an assumption where it is written, which the early drafts did ("proposed"), and keep assumptions out of anything that looks final, such as GitHub milestones with dates.

## P-007 — Bundled fonts did not appear in the app

- **Date found:** 2026-11-13
- **Phase / milestone:** M2 Design (style preview)
- **Who:** assistant
- **Status:** Solved

**What happened**
After Inter and Source Serif 4 were added to the shared package, the app was rebuilt and screenshots were taken. The build succeeded and the analyzer reported no issues, but the screenshots still showed the Windows system font: headings that should have been serif were not.

**Cause**
The build had reused earlier output and did not pick up the new font declarations in the package's `pubspec.yaml`. The built app's font list (`FontManifest.json`) did not contain the new fonts.

**What we tried**
1. Looked at the screenshots rather than trusting the successful build: the fonts were visibly wrong.
2. Opened the built app's font list: the fonts were missing from it.
3. Cleaned the build and rebuilt: the fonts appeared.

**Solution**
`flutter clean`, then rebuild. The font list was checked again before taking new screenshots.

**Lesson**
"It compiled" does not mean "it worked". A change to assets or fonts needs a clean build, and visual work has to be checked by looking at it.

## P-008 — A documentation update failed and a commit silently did not happen

- **Date found:** 2026-11-13
- **Phase / milestone:** M3 Backend Services
- **Who:** assistant
- **Status:** Solved

**What happened**
The documents are updated by small scripts and then committed in one command. One script crashed half-way (a Windows path containing a backslash was treated as an escape sequence in a text replacement). Because the commit was chained after the script, nothing was committed or pushed, and the summary for that step had already been written as if it had been.

**Cause**
A script error in the middle of a chain of commands, and a summary prepared before reading the output.

**Solution**
The output was read before anything was reported, the script was fixed to treat replacement text literally, and it was rerun. The commit and push were then checked. Earlier, a similar failure came from a quotation mark inside a command; since then, longer scripts are written to a file and run from there instead of being typed inline.

**Lesson**
Read the result of every step before describing it. Chain a commit after the work so that a failure stops the commit (which is what happened here and is why nothing half-done was pushed). Never report from the plan; report from the output.

## P-009 — A hand-written placeholder was used where a real bcrypt hash was needed

- **Date found:** 2026-11-13
- **Phase / milestone:** M3 Backend Services
- **Who:** assistant
- **Status:** Solved before it ran

**What happened**
To make a login for an unknown user take as long as one for a known user (E-013), the service compares the password against a spare hash. The first version of `AuthService` contained that spare hash as a constant typed by hand to look like a bcrypt hash.

**Cause**
Writing something that looks right instead of producing something that is right. A made-up string is very unlikely to be a valid bcrypt hash; the library would have rejected it immediately, the timing protection would silently not have worked, and nothing would have reported it.

**Solution**
Caught on re-reading, before the code was compiled. The constant was removed and the spare hash is now computed by the real hasher when the service starts.

**Lesson**
Never invent a value that has a format: compute it. And a protection that fails silently needs a test; the test `anUnknownUserGetsTheSameMessageAsAWrongPassword` covers the message, though not yet the timing.

## P-010 — The requested typeface (SF Pro) could not be used

- **Date found:** 2026-11-13
- **Phase / milestone:** M2 Design
- **Who:** licensing
- **Status:** Worked around

**What happened**
The project owner asked for Apple's SF Pro, to get an Apple-like interface.

**Cause**
Apple licenses SF Pro only for software that runs on Apple platforms. These are Windows apps, so bundling it is not allowed.

**Solution**
Inter was used for interface text and Source Serif 4 for headings. Both are open source under the SIL Open Font License, which allows bundling, and both were taken from their official GitHub repositories with their license files.

**Lesson**
Check the license of an asset before designing around it.

## P-011 — Diagram layout faults, and deleted diagrams coming back

- **Date found:** 2026-11-13 (repeatedly)
- **Phase / milestone:** M2 Design, M3 Backend Services
- **Who:** assistant
- **Status:** Solved

**What happened**
The diagrams are generated by scripts and exported to images. Many first exports had faults: lines drawn through boxes (class diagrams, use case, composite structure, the user-service diagram), text cut off or overflowing (method names, wireframe labels, activity decisions, cover titles breaking in the middle of a word), labels hidden under other labels (component diagram), a placeholder `<orderId>` that vanished because it was read as HTML, and titles that were not centered.

Separately, after the deployment, package, and composite structure diagrams were removed on request, the script that generates the other diagrams still contained them, so every later run recreated the three deleted files.

**Cause**
Positions are calculated, not seen, so a layout can be wrong in ways only visible in the image. And the removed diagrams were deleted from the repository but not from the generator.

**Solution**
Every exported image is opened and looked at before it is committed; each fault above was fixed and the image exported again. The recreated files are deleted after each run, and the list of changed files is checked before committing so that only the intended diagrams change.

**Lesson**
Generated output has to be inspected, every time. Removing something means removing it from whatever generates it, not only from where it ends up. The second half of this is still open: see "Known gaps".

## P-012 — Maven was not available from the package manager

- **Date found:** 2026-11-13
- **Phase / milestone:** M3 Backend Services (setup)
- **Who:** environment
- **Status:** Solved

**What happened**
Java and MongoDB were installed with `winget`. Maven is not in the winget catalog.

**Solution**
Maven 3.9.9 was downloaded from Apache's own archive, its SHA-512 checksum was compared with the one Apache publishes before unpacking it, and its `bin` folder was added to the user PATH.

**Lesson**
When a tool has to come from a direct download, take it from the publisher and verify the checksum.

## P-013 — Small things that went wrong

Problems that cost minutes, not hours. Listed so the record is complete.

| What happened | Who | What was done |
|---|---|---|
| The project folder could not be renamed from `csce310-bookstore` to `CSCE310-Bookstore`: Windows treats names that differ only in capital letters as the same | Environment | Kept the lower-case name |
| The Mermaid diagrams in the first docs had to be replaced when the owner asked for draw.io | Assistant | Redrawn in draw.io; draw.io Desktop installed for exporting |
| The first headless screenshot of the sample bill produced no file | Assistant | Run a different way (a separate browser profile and waiting for it to finish) |
| The sequence diagram was drawn in color; the owner wanted it plain | Assistant | Redrawn without color |
| In the catalog preview, price and availability overlapped on narrow cards, and "Only 2 left" was cut off | Assistant | Shorter wording on cards; found by looking at the screenshots |
| The detail panel's "Rent" button was cut off at the default window height | Assistant | The panel now scrolls when the window is short |
| The login response sent `"token": null` on endpoints that have no token | Assistant | Empty fields are no longer sent; a test checks it |
| The first timing check of the service reported "server not up" although it was | Assistant | The check itself was hitting the `localhost` delay that became P-004 |
| The screen class was named `CatalogScreen` in code but `SearchScreen` in the approved class diagram | Assistant | Code renamed to match the diagram |
| The use case diagram was missing the mail server as an actor | Assistant | Added after the owner questioned the actors |
| Releasing v0.3.0, the script's safety check stopped it three times before anything was committed: GitHub's issue list lagged a few seconds behind a change; an empty JSON list counts as one item in Windows PowerShell; and a git line-ending warning was treated as an error | Assistant | Each fixed in the script and rerun. Nothing half-done reached GitHub, because the commit and tag came after the checks (as P-008 taught) |
| Building the customer app's screens, the assistant's screen tests and screenshots found seven faults before anything was committed: rows that overflowed in narrow places (the "Create an account" line, the due-date line, button labels, the Buy/Rent choice at 1024 px wide); the manager refusal message being lost when the logout reopened the login screen; the login screen's fanned covers hiding each other's titles; and a book's detail panel staying open after a new search no longer showed that book | Assistant | Each fixed, and each overflow and behavior is now covered by a test (one test drives every screen in a 1024 x 700 window) |
| The assistant said a rounding test would show the app charging $3.55 instead of $3.56; the test passed on the old code, so the old code happened to be right for that price | Assistant | Said so at the time. The rent price is now worked out in whole cents anyway, so it no longer depends on how a price happens to be stored |
| `dart format` reformatted twelve files of the shared package to 80-column lines, including files that had not been changed | Assistant | Found in `git status` before committing; the untouched files were restored and the changed ones formatted at the 150 columns the project uses |
| The first class diagram of the built customer app had three lines through boxes and a label over text (P-011 again) | Assistant | Found by looking at the exported image; boxes moved and one line routed above the others |
| The v0.3.0 release was published with `â€”` in its title instead of a dash: Windows PowerShell read the release script, saved as UTF-8 without a marker, in the old Windows encoding | Assistant | Found by reading the title back from GitHub character by character; corrected with an escaped character. The release notes were unaffected |
| The owner's first `flutter run` of the customer app, from the Claude app's Terminal panel, failed with hundreds of "Type not found" errors: that panel could not read Flutter's package folder in `%LOCALAPPDATA%\Pub\Cache`, so every package looked empty | Environment | The assistant built the debug app itself and the owner started the `.exe`; the app worked. `clients/README.md` says to run from a normal PowerShell window or VS Code |
| The management app's check against the real services failed on its first run: order-service had been started before `GET /api/orders/{id}` was added, so the running copy did not know it | Assistant | Services restarted; every call then answered as expected. Lesson: restart a service after changing it, before checking it for real |
| The orders row of the management app overflowed by 84 pixels in a 1024-wide window once "Mark as paid" appeared on it | Assistant | Found by the small-window test before the owner saw it; the payment column now has a fixed width |
| The stand-in data of the management app's tests had an order whose total ($4.50) did not match its one item ($4.80) | Assistant | Found when the bill test showed both numbers; the stand-in data corrected |
| The manager-app commit added `OrderService.get()` and `GET /api/orders/{id}`, but did not update the order-service class diagram, and left the test count in the file map at 37 and an API note saying the answer has no `billFile` (it has) | Assistant | Found while adding the account page; all three corrected in the next commit. Lesson: regenerate the class diagram of every service a change touches, not only the app's |
| On the account page, the column holding "Payment pending" and Pay was 100 pixels too narrow, and a pending row was taller than a paid one | Assistant | The overflow was found by the 1024 x 700 test, the height by looking at the screenshot; the column is now 320 wide and 42 high |
| After logging out, the preferences still belonged to the last customer, so a change made before the next log in would have been saved into that customer's settings | Assistant | Found by a screen test before it shipped. Logging out now lets go of them (`Preferences.forget()`), and a test checks it |
| `manual_check.py` (written in M3) failed one check after the owner's test orders: it picked a book with at least 2 copies but takes 3 from it before the "a real book and a missing book: 404" call, so the service rightly answered 409 (sold out) first | Assistant | Not a service fault. The check now picks a book with at least 4 copies; all 41 checks then passed |
| Of the first 27 cover photos found on Open Library by title, six were wrong for a shop: two plain library bindings, two faded editions, a French *A Brief History of Time*, and a Spanish/English *Very Hungry Caterpillar*; two books had none | Assistant | Found by laying every cover out on one contact sheet before using any. Each was replaced with a well-known English edition, found by ISBN, and checked again |
| The screenshot test hung for over ten minutes when waiting for the cover photos to load, both from the internet and from files | Assistant | Stopped, and no test process was left. The photos are now downloaded beforehand (`tools/screenshots/fetch_covers.py`) and decoded before the screen is drawn, so nothing is waited for |
| With the new sign and the shelf row, the tests found two layout faults before anything was committed: the shelf tabs 2 pixels too tall for their row, and the search field 26 pixels too narrow in a 1024-wide window | Assistant | The tabs got less padding. The search field now drops its "Ctrl F" hint when space is short, and in a narrow window the account button shows only its icon |
| The class diagrams of this change at first had the color note on top of the new MooneysSign box, and SearchScreen touching BookApi (P-011 again) | Assistant | Found by looking at each exported image; boxes moved and lines shortened |
| Adding 54 books, two of the agents that each picked one shelf chose the same book (*The Immortal Life of Henrietta Lacks*, for Nonfiction and for Science) | Assistant | Found by the lead's duplicate check before anything was saved; the Science copy was replaced by *Silent Spring*. The lead also replaced the *Frankenstein* cover (a nude painting) with a plainer edition |
| With 81 books, three app tests failed: the book they clicked (*Clean Code*) was no longer on the first screen of the list or grid | Assistant | The tests now scroll to the book, or search for it, as a person would |
| The account page's first diagram had its new line from SearchScreen cut across the OrderApi box (P-011 again) | Assistant | Found by looking at the exported image; the line now leaves SearchScreen's side and turns down |
| Reviews (extra credit): a review sent with the book's id in capital letters was stored under that second spelling. MongoDB finds a book by its id in any case, so one customer could review the same book twice, and those reviews were missing from its rating. The tests had not shown it, because the stand-in database matched ids exactly and its ids had no letters | Assistant | Found by the independent reviewer (E-050), against a real MongoDB in a scratch database, before anything was committed. A review is now stored under the book's own id. The stand-in database now accepts any case, as MongoDB does; a test sends the id in three spellings and expects one review, and another checks the real MongoDB |
| Sales report (extra credit): best sellers tied on copies and revenue were put in order with every capital letter before every lower-case one ("Zebra" before "apple basics") | Assistant | Found by the independent reviewer before anything was committed. The order is now alphabetical whatever the case; a test checks exactly that pair |
| Review dialog (extra credit): it could be closed with Esc or a click outside while a save was running, so the review was saved but the panel did not show it. And its "n / 1000" count counted UTF-16 units while book-service counts code points, so with emoji the count and the limit disagreed with the service | Assistant | Both found by the independent reviewer before anything was committed. The dialog cannot be closed during a save (Esc still closes it otherwise); the count and the limit now both count code points. Three screen tests cover it, and both failing ones were seen to fail before the fix |
| Reports tab (extra credit): the third tab made the manager's top bar overflow at 1024 px. The first fix hid the username below a fixed 1100 px width, which only worked for short names: a 50-character name still overflowed at 1100, 1150, and 1440 px, and below 1100 px the name was only in a tooltip | Assistant | The second half found by the independent reviewer before anything was committed. The name now shortens with an ellipsis at any width and has a "Logged in as" tooltip; a test drives a 50-character name at four widths, and another checks that an 18-character name ("store.manager.2026") shows in full at 1024 px in the real typeface |

## P-014 — A manual check failed and left a service running

- **Date found:** 2026-11-13, finished 2026-11-16
- **Phase / milestone:** M3 Backend Services
- **Who:** assistant
- **Status:** Solved

**What happened**
After book-service passed its tests, it was started together with user-service and called by hand from a PowerShell script. The first run printed nothing useful and ended with errors. The second run showed search and the login checks working, but "manager adds a book" failed with no response at all, which made the three checks after it meaningless. And after the first run, book-service was still running in the background.

**Cause**
Two mistakes in the checking script, none in the service:

1. PowerShell does not distinguish capital letters in variable names. The script kept the service's process in `$b` and the address in `$B`; the second overwrote the first, so the script could no longer stop the service it had started.
2. The test book's title had spaces in it ("Run Check Book"). The way the script passed it to the command split it into pieces, so the request was never sent.

**What we tried**
1. Found and stopped the leftover process, and added a check at the end of every run that no service process is left.
2. Renamed the variables: this fixed the first mistake and exposed the second.

**Solution**
The manual check was rewritten in Python, which sends requests directly instead of building a command line. Each check now states the result it expects and the script says plainly whether all passed. All 16 checks passed, in 3 to 38 ms. The work was committed in between as "work in progress", with the three unverified endpoints named as unverified.

**Lesson**
Write checks in a language that handles data properly rather than gluing text into commands. A check must say what it expects, so that a failure cannot be mistaken for a pass. Anything a script starts, it must be sure to stop. And when a check fails, say what was and was not verified instead of rounding up.

## P-015 — order-service passed all its tests with faults a review then found

- **Date found:** 2026-11-16
- **Phase / milestone:** M3 Backend Services
- **Issue:** #10
- **Who:** assistant
- **Status:** Solved, with three limits left open (see "Known gaps")

**What happened**
order-service was written test-first: the tests were written, seen to fail, and then the code made them pass (83 tests, then all 33 checks on the running service). A code review of the result, done before committing, still found ten things. None was a wrong answer to a request, which is why no test had caught them.

**What the review found, and what was done**

| Found | Done |
|---|---|
| The bill's wording said "7 days" and "10%" as text, separate from the constants the charge is calculated from. Changing the rule would have left every bill wrong | Fixed: the rule moved to `pricing.py`; the bill reads it from there. A test changes the rule and checks the bill follows |
| The bill file was written in place, so someone opening it at the same moment could get half a file | Fixed: it is written beside the real file and swapped in, in one step |
| The manual check worked out the expected rent with ordinary decimal fractions (`float`), which can differ by a cent from the service's exact arithmetic. A correct service could have been reported as failing | Fixed: the check uses exact arithmetic too |
| A port setting that is not a number crashed start-up with a raw error | Fixed: the message names the setting. A test covers it |
| The API document and the sequence diagram still described the first design (`emailSent`; save the order, then reduce copies) | Fixed in the same commit: both updated |
| If book-service takes a copy but its answer is lost, the copy is not given back | Not fixed: logged as an error naming the book. Known gap |
| The MySQL tests use up real order numbers | Not fixed: the services' account cannot create a test database. Documented. Known gap |
| The list of orders loads every item, though the list shows none | Left: fine at this size. Known gap |
| One HTTP connection object is shared by all request threads | Left: the same as book-service, and no fault was seen under the checks |
| The error classes and session check are copies of book-service's | Left on purpose: architecture decision 20 |

**One more, found while fixing**
The test written for the "swapped in, in one step" fix passed before the fix was made. It checks that the new text is there and no draft is left behind, which was already true. It cannot show that a reader never sees half a file. The test's own comment now says so.

**Lesson**
Tests written first prove the answers; they do not prove what happens around the answers: a rule written twice, a file read mid-write, a check that is itself wrong. Review the code before committing, as a separate step. And when a new test passes before its fix, say what it really proves instead of counting it.

## P-016 — The first real bill email arrived with its layout broken

- **Date found:** 2026-11-16
- **Phase / milestone:** M3 Backend Services
- **Issue:** #16
- **Who:** assistant
- **Status:** Solved. The owner opened the second email (order 1041) in Gmail and sent a screenshot: heading, details, table, and typeface all as designed

**What happened**
The first bill sent through Gmail arrived, with the right content, but looked wrong: "Bookstore" and "Bill" were pushed together, the Order ID, Date, and Customer were squeezed into one corner, and the serif typeface was replaced by Gmail's own. The same bill opened as a file in a browser looked right. The owner found it by opening the email and sending a screenshot.

**Cause**
The bill was designed in M2 as "one HTML file that is also the body of the email", and was only ever looked at in a browser. Mail programs show less HTML than browsers. Gmail ignores `display: flex`, which placed the heading and the details side by side, and it ignores styles put on `<body>`, which carried the typeface and the width.

**Solution**
The heading and the details are now tables, and the page's own styles sit on a wrapper inside the body. Both are shown by mail programs and browsers alike. A test fails if flex layout or a body style comes back. The sample in `docs/02-design/bill` is now produced by the service's own code, so the design sample and the real bill cannot drift apart. A second real email was sent with the new layout.

**Lesson**
"Gmail accepted it" is not "it looks right", in the same way that "it compiled" was not "it worked" (P-007). Something made to be shown in two places has to be looked at in both. This could not be checked without the owner's inbox, and was listed as not verified, which is how it was caught the same day.

## P-017 — Release builds of the apps are blocked by Windows security

- **Date found:** 2026-11-17
- **Phase / milestone:** M4 Desktop Clients
- **Issue:** #11
- **Who:** environment
- **Status:** Open. Debug builds are used meanwhile

**What happened**
`flutter build windows --release` of the customer app failed: "An Application Control policy or security policy has blocked execution", for `gen_snapshot.exe`, the Flutter tool that compiles Dart ahead of time for release builds.

**Cause**
Smart App Control (see P-002, P-003) blocks this unsigned program. Unlike P-002, a second try was blocked too, so it is not a one-time first-run check.

**What we tried**
1. Built again: blocked again.
2. Built in debug mode, which does not use `gen_snapshot`: it works, and the app runs.

**Solution so far**
The apps are built and run in debug mode, which is also how they are run from VS Code (F5). No security setting was changed. Debug builds are slower to start and larger, but behave the same.

**Solution (2026-11-17)**
The owner asked for an installable build. Release builds are now made on another machine: GitHub's Windows machine, by the release workflow (`.github/workflows/windows-release.yml`), which has no Smart App Control. Smart App Control stays on here.

**What that showed**
The installer and the portable apps built there are blocked on this computer too: "An Application Control policy has blocked this file". It blocks unsigned programs it does not know, downloaded or not. Debug builds compiled on this computer still run. So:

1. The installer is tested on GitHub's machine instead, by `installer/test-installer.ps1`. It installs silently, checks every file and Start menu entry, opens both apps, and uninstalls; the release is not published unless it passes.
2. A grader whose computer has Smart App Control on will be blocked the same way. INSTALL.md says so and gives the way round: build from source, as debug builds work. Code signing would fix it, but costs money and was not done.

**Status:** solved for building; the unsigned-installer limit is recorded under Known gaps.

## P-018 — user-service once did not start in the fresh-machine test of v1.2.0

- **Date found:** 2026-11-18
- **Phase / milestone:** M6 extra credit (release v1.2.0)
- **Who:** environment (cause unknown); assistant (the check could not say why)
- **Status:** Not reproduced. Better reporting added

**What happened**
In the fresh-machine test of v1.2.0 on GitHub, setup and the demo data loaded fine, but `manual_check.py` stopped at once: "user-service did not start". The Java process ended about 14 seconds in, before opening its port.

**Cause**
Unknown. The message gave only the path of the service's log, and that file is gone when GitHub's machine is thrown away. The same 41 checks passed here with the demo data loaded, and the same test, run again on a new GitHub machine with nothing changed, passed every step.

**Solution**
`manual_check.py` now prints the last 20 lines of a service's log when it does not start, so a repeat would show why. v1.2.0 itself is not changed: the failure was not in its files.

## P-019 — The README described a branch-and-pull-request workflow that was never used

- **Date found:** 2026-11-18
- **Phase / milestone:** after M6 (front page redone)
- **Who:** assistant
- **Status:** Fixed

**What happened**
The README's "Workflow" section said every task was done on its own branch and merged into `main` through a pull request. A checker found that this never happened: `git log --merges` shows no merges, and `main` is the only branch. Work was committed straight to `main`, with GitHub issues for the tasks.

**Cause**
The section was written at the start (M1) as the plan, and was not checked against what was actually done.

**Solution**
The new README describes what was really done. `docs/04-planning/versioning.md` still gives the branch rule for later patches (v1.1.x on a fix branch).

## P-020 — Smart App Control began blocking Flutter's dart.exe

- **Date found:** 2026-11-18
- **Phase / milestone:** after M6
- **Who:** environment
- **Status:** Open. The tests run on GitHub instead

**What happened**
`flutter test` stopped with "dart.exe was blocked by your organization's Device Guard policy". It was blocked twice in a row. Earlier the same day it worked: the screenshots in this change were drawn with it.

**Cause**
Smart App Control (as in P-002, P-003, P-017). `dart.exe` is unsigned, and it has not changed since 2026-11-09 (Flutter 3.50.0, Dart 3.14.0), so the block comes from Windows, not from a new file.

**Solution so far**
No security setting was changed. The Flutter tests of this change were run on GitHub's Windows machine with a manual run of the release workflow, which runs every test suite and publishes nothing when it is not started by a tag.

## Known gaps

Things that are known to be unfinished or unverified, so nobody is surprised later.

| Gap | Since | Plan |
|---|---|---|
| `uml.py` still writes the three diagrams that were removed, and has not been run from `tools/diagrams`. (`flows.py` was run from there on 2026-11-16 and changed only the diagram that was meant to change) | M2 | Remove the three from `uml.py`; run it once and check `git status` shows no change |
| The installer and the apps are not code-signed: Windows warns "unknown publisher", and where Smart App Control is on (as on the development computer) it blocks them (P-017) | M5 | Documented in INSTALL.md with the way round (build from source). Signing would need a paid certificate |
| `setup.cmd`'s winget installs have not run anywhere: the development computer had everything, and the fresh-machine test on GitHub switched on what that machine already had. The rest of setup was proven there from nothing | M5 | Accept; the instructions say what to install by hand if winget is missing |
| The bill email has been seen to look right in Gmail in a desktop browser only. Other mail programs (Outlook, phone apps) are untested | M3 | Test others in M5 if wanted |
| If book-service takes copies for an order but its answer does not arrive within 3 seconds, the order fails and those copies are not given back. order-service logs an error naming the book | M3 | Accept and document; a manager can correct the number of copies (FR14). Rare on one machine |
| The MySQL tests of order-service run in the real `bookstore` database and use up order numbers, so real order ids are not consecutive | M3 | Accept, or have the owner grant the services' account a `bookstore_test` database |
| `GET /api/orders` returns every order at once, and loads their items | M3 | Fine for a course project; add paging if the list grows |
| `activity-place-order` and `class-services` (drawn in M2 by `uml.py`) still show the first design: the order is saved before the copies are reduced | M3 | Update with `uml.py` when its other fault is fixed. The sequence diagram and the as-built class diagram are current |
| How the app's animations and scrolling feel has not been judged by a person | M2 | The owner tries the preview; adjust in M4 |
| Trackpad scrolling, screen readers, and a color-blindness simulation are untested | M2 | Test during M5 |
| The timing protection of E-013 has a test for the message but not for the timing | M3 | Add a timing test, or accept and document |
| Sessions never expire; they end only at logout | M2 | The PRD asks for exactly this (FR2). Noted in case an expiry is wanted |
| Returning a rented book is not built: a rented copy never comes back to the shelf by itself, and the account page keeps showing it as late | M2 | Not asked for by the PRD. A manager can raise the number of copies (FR14) |
| Any logged-in customer can review any book, not only one who bought or rented it. Checking for a purchase would make book-service call order-service, which already calls book-service | M6 | Decided on purpose (E-048) |
| Reviews are not moderated: a manager cannot remove or hide one. Only its writer can change or delete it | M6 | Decided on purpose (E-048) |
| `database/seed.py` reloads the books, which gives them new ids, but does not touch the `reviews` collection. Reviews of the old ids are left behind; nothing shows them, and nothing removes them | M6 | Harmless, as reviews are only read by book id. Clear the collection in the seed script if it matters |
