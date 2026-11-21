# User acceptance test videos: recording script

The course asks for YouTube recordings of user acceptance testing of **all** functional requirements (FR1 to FR14). This is the script to follow when recording them. It is **one video**, recorded as four parts back to back (about 16 to 20 minutes); below, "video 1" to "video 4" mean those parts. Add a YouTube chapter (a timestamp in the description) at the start of each part:

| Part | What it shows | Requirements | Length |
|---|---|---|---|
| 1 | Accounts: create an account, log in, stay logged in, log out | FR1, FR2, FR3 | 3 to 4 min |
| 2 | Shopping: search, choose, buy and rent, bill, saved bill, emailed bill | FR4 to FR10 | 5 to 6 min |
| 3 | The manager: separate app, orders, payment status, books | FR11 to FR14 | 4 to 5 min |
| 4 | Extra credit: reviews and ratings, account page with order history, sales report | Beyond the PRD | 4 to 5 min |

Each table has four columns:

- **Step**: the number used in the checklist in section 8.
- **What to do**: the exact clicks and typing.
- **What to say**: one short sentence, naming the requirement.
- **Expected result**: what must be visible on screen. This is the acceptance criterion. If it does not appear, stop, fix the problem, and record the step again.

Words in quotes in "What to do" and "Expected result" are labels on screen, taken from the app code (`clients/*/lib`). Quotes in "What to say" are the spoken sentence.

Record the videos in order. Video 2 uses the account made in video 1, video 3 uses the order placed in video 2, and video 4 uses the order marked as paid in video 3.

## 1. Before every video

| Check | How |
|---|---|
| The three services are running | Nothing to do: opening either app starts them (the login screen says "Starting the bookstore services" for about 10 seconds). Or double-click `start-services.cmd` in the repo root first. |
| The test accounts exist | `customer1` / `customer123` and `manager1` / `manager123` (made by `python database/seed.py`). |
| The demo data is there | `python database/demo_data.py`. It keeps the demo data if it is already there (14 customers, 100 past sales, reviews). Needed for video 4's sales report. |
| The apps are ready | **Mooney's** and **Mooney's Manager** from the Start menu (after the installer), or `flutter run -d windows` in `clients/customer-app` and `clients/management-app`. |
| Nothing private is on screen | Close `services/.env`, any terminal that printed it, password managers, and other email. Turn off notifications (Focus, or Do not disturb). The bill email in video 2 shows the store's sending Gmail address: use a Gmail account made for the demo, or accept that its address is visible. |
| Screen | 1920 x 1080, scale 100% if possible, so the text is sharp in the video. Light mode is easier to read on YouTube. |

**Never show the Gmail app password or the file `services/.env`** in any video. If it appears by mistake, delete that recording and record again; do not upload it.

Afterwards, run `stop-services.cmd` and confirm no service is left running.

## 2. Video 1: accounts (FR1, FR2, FR3)

**Before you record:** services running. Mooney's open on the "Log in" screen. Choose a new username that does not exist yet (below: `<new-user>`), and an email address whose inbox you can open on screen in video 2 (below: `<your-email>`). A separate Gmail address made for the demo is best.

Usernames and emails must both be unique. If you record steps 1.5 and 1.6 again, the first take has already used `<new-user>` and `<your-email>`, so 1.6 would fail with "Username or email already in use". Each take needs a new username **and** an email not used before. With Gmail, use a plus address (for example `name+uat2@gmail.com`): it reaches the same inbox and passes the app's email check.

| Step | What to do | What to say | Expected result |
|---|---|---|---|
| 1.1 | Show the Mooney's "Log in" screen. | "This is Mooney's, the customer app. I will test the account requirements, FR1 to FR3." | "Log in", "Welcome back.", fields "Username" and "Password", the "Log in" button, and "New here? Create an account". |
| 1.2 | Click "Create an account". | "FR3: a new user can create an account." | The "Create an account" screen: "For customers. Managers are added by the store." Fields "Username", "Email", "Password", "Confirm password". The note "Your password is stored only as a secure hash." |
| 1.3 | Leave every field empty. Click "Create account". | "Empty fields are refused." | Under the fields: "Choose a username", "Enter your email address", "At least 8 characters". Nothing is sent. |
| 1.4 | Type username `ab`, email `not-an-email`, password `short`, confirm password `other`. | "FR3 asks for a valid email; the app checks every field." | "At least 3 characters", "This does not look like an email address", "At least 8 characters", "The two passwords are not the same". |
| 1.5 | Change the username to `customer1` (taken), email to `<your-email>`, password and confirm password to the same 8 or more characters. Click "Create account". | "A username that is already taken is refused by the server." | The field errors are gone. An error under the fields: "Username or email already in use". |
| 1.6 | Point at the note "Your password is stored only as a secure hash." Change the username to `<new-user>`. Click "Create account". | "With a free username, the account is created. FR3: the password is stored only as a hash." | Back on "Log in". The note "Account created. Log in with your new password." The username is filled in and the cursor is in "Password". |
| 1.7 | Type a wrong password. Click "Log in". | "FR1: a wrong password is refused." | "Wrong username or password". The password field is emptied. |
| 1.8 | Leave "Password" empty. Click "Log in". | "Empty fields are refused too." | "Enter your password" under the field. |
| 1.9 | Type the right password. Click "Log in". | "FR1: with the right password the system logs me in and starts a session." | The search screen: the Mooney's sign, "Search by title or author", the shelves (All, Fiction, Nonfiction, Kids, Science, Technology), the books, and `<new-user>` at the top right. |
| 1.10 | Click the `<new-user>` button (tooltip "Your account"). Then the back arrow ("Back to search (Esc)"). | "FR2: I stay logged in as I move around the app." | "Your account" with Profile: Username `<new-user>`, Email `<your-email>`, Account "Customer". Back on search, still logged in, not asked to log in again. |
| 1.11 | Click the log-out icon (tooltip "Log out"). | "FR2: the session lasts until I log out." | Back on "Log in". The search screen cannot be reached without logging in again. |
| 1.12 | Log in as `manager1` / `manager123` in Mooney's. | "Each app is for one role. A manager cannot use the customer app." | Still on "Log in", with the note "This app is for customers. Managers log in to the management app." |

## 3. Video 2: shopping and the bill (FR4 to FR10)

**Before you record:** services running, and the bill email working (the Gmail address and app password are in `services/.env`; check this off camera). Mooney's open on "Log in". A browser open on the Gmail inbox of `<your-email>`, in another window, already signed in. A File Explorer window open on `services\order-service\bills`.

| Step | What to do | What to say | Expected result |
|---|---|---|---|
| 2.1 | Log in as `<new-user>`. | "I am logged in as the customer I created in the first video." | The search screen, "All books", and the number of books. |
| 2.2 | In "Search by title or author", type `orwell`. | "FR4: the keyword is matched against the author." | "Results for "orwell"". Only books by George Orwell. A line such as "N of M books match in title or author". |
| 2.3 | Clear the search (the x, "Clear search (Esc)"). Type `hobbit`. | "FR4: and against the title." | "Results for "hobbit"". The Hobbit by J. R. R. Tolkien. |
| 2.4 | Type `zzzz`. | "A keyword with no match says so." | "No books match "zzzz"" and the "Clear search" button. |
| 2.5 | Clear the search. Click the "Show as a list" icon. | "FR5: the results are a clear list with title, author, and price." | One row per book: cover, title, author, rating, copies available, price. |
| 2.6 | Click a book. | "FR6: I select a book from the results." | A panel on the right: cover, title, author, copies available, "Buy" with the price, "Rent for 7 days" with the rent price, and "Renting costs 10% of the price. The book is due back after 7 days." |
| 2.7 | Click "Buy". | "I add it to my order, to buy." | A message "Added to order: <title>". The top button reads "Your order (1)". The panel says "This book is already in your order." |
| 2.8 | Click a second book. Click "Rent for 7 days". | "FR6 and FR7: I can select more than one book, and rent instead of buy." | "Added as a 7-day rental: <title>". "Your order (2)". |
| 2.9 | Click a third book. Click "Buy". Then click "Your order (3)". | "Now I review the whole order." | "Your order", "3 books. Choose to buy or rent each one, then place the order." Each book shows "Buy" and "Rent 7 days" with both prices. The rented one shows "Due back <date> if ordered today". The summary shows "Bought (2)", "Rented for 7 days (1)", and "Total". |
| 2.10 | On the third book, click the bin ("Remove from order"). Then click "Undo" in the message. | "I can change my mind before placing the order." | "Removed: <title>", then the book is back after Undo. The total changes and changes back. |
| 2.11 | Point at the line under the button: "Your bill is shown next, and a copy is emailed to <your-email>." Click "Place order". | "FR7: buying and renting are finalized in a single transaction that creates one order." | The button shows "Placing order…", then the bill screen: "Order <number> placed". |
| 2.12 | Show the bill. Do not click "Pay now". | "FR8: the bill has a unique order ID, the items, the price of each, and the total amount due." | Mooney's "BILL" with "ORDER ID", "DATE", "CUSTOMER" (`<new-user>` and the email). Columns "ITEM", "TYPE", "DUE BACK", "QTY", "PRICE": the two bought books as "Buy", the rented one as "Rent (7 days)" with its due date and 10% price. "Payment pending". "Total amount due" with the total. Write down the order number. |
| 2.13 | Point at the line under the title. | "FR10: the bill is emailed automatically." | "A copy of this bill is on its way to <your-email>." (If it says "This bill is saved with your order…" instead, email is not set up: stop and fix it off camera.) |
| 2.14 | Switch to File Explorer, `services\order-service\bills`. Press F5. Double-click `bill-<number>.html`. | "FR9: the bill was saved automatically as an HTML file, which the manager can print and post." | The file `bill-<number>.html` is in the folder, with today's time. It opens in the browser with the same order ID, items, prices, and total. |
| 2.15 | Switch to the browser with Gmail. Refresh the inbox. Open the newest email. | "FR10: and here is the same bill in the customer's inbox." | An email with the subject "Your Mooney's bill: order <number>", showing the bill with the same items and total. Do not open settings or any other email. |
| 2.16 | Back in Mooney's, click "Log out". | "That covers FR4 to FR10." | Back on "Log in". |

## 4. Video 3: the manager (FR11 to FR14)

**Before you record:** services running. Mooney's Manager open on "Log in". Mooney's (customer app) also open, logged in as `customer1`, in another window (for step 3.14). Know the order number from video 2.

| Step | What to do | What to say | Expected result |
|---|---|---|---|
| 3.1 | Show the Mooney's Manager "Log in" screen. | "FR11: managers have a separate management app, Mooney's Manager." | "Log in", "Management. For store staff only." |
| 3.2 | Log in as `customer1` / `customer123`. | "FR11: a customer account is refused here." | Still on "Log in", with "This app is for managers. Customers log in to the customer app." |
| 3.3 | Log in as `manager1` with a wrong password. | "A wrong password is refused." | "Wrong username or password". |
| 3.4 | Log in as `manager1` / `manager123`. | "With a manager account, the management interface opens." | The bar shows the Mooney's sign, "MANAGER", the tabs "Orders", "Books", "Reports", and `manager1`. |
| 3.5 | Stay on "Orders". | "FR12: the manager sees a list of all purchase orders." | "Orders", "N orders, M waiting for payment. Newest first." Columns "ORDER", "CUSTOMER", "DATE", "TOTAL", "PAYMENT". The order from video 2 is at the top, by `<new-user>`, "Pending". |
| 3.6 | Click the filters "Pending", then "Paid", then "All". | "Orders can be filtered by payment status." | Each filter shows only those orders, with the counts on the tabs. |
| 3.7 | Click the order from video 2 (the row, not the button). | "FR13: the manager selects an order." | A window "Order <number>" with the same bill as the customer saw, "Payment pending", and the buttons "Mark as paid" and "Print bill". |
| 3.8 | Click "Print bill". | "FR9: the app fetches the saved bill from order-service and opens it in the browser, ready to print and post." | The browser opens a copy of the bill (`bookstore-bill-<number>.html` in the temporary folder) with the same order ID, items, and total. Close the browser tab and go back to the app. |
| 3.9 | Click "Mark as paid". | "FR13: the manager changes the payment status from Pending to Paid." | The status on the bill becomes "Paid". The button becomes "Mark as pending". |
| 3.10 | Close the window ("Close (Esc)"). Click "Paid". | "The list shows the new status." | The order is in the "Paid" list with the "Paid" status. (Leave it paid: video 4 uses it.) |
| 3.11 | Click "All". Click "Mark as paid" on a different pending order (a demo order). Then "Undo" in the message. | "It can also be done from the list, with Undo." | "Order <id> marked as paid", then the order goes back to "Pending" after Undo: "Order <id> is waiting for payment again". |
| 3.12 | Click the "Books" tab. Click "Add book". Leave all fields empty. Click "Add book" in the window. | "FR14: the manager adds a new book. Empty fields are refused." | Window "Add a book". Under the fields: "Enter the title", "Enter the author", "Enter the price", "Enter the number of copies", "Choose a shelf". |
| 3.13 | Type a title and an author. Price `0`, copies `3`. Click "Add book". Then change the price to `12.50`, choose the shelf "Fiction", and click "Add book". | "A price of zero is refused. With valid details, the book is added." | First: "The price must be more than 0" and "Choose a shelf". Then the window closes, a message "Added: <title>", and the book is in the list with its price and "3 copies". |
| 3.14 | Switch to Mooney's (customer app, `customer1`). Search for the new title. Click it. | "The new book appears in the customers' search at once." | The new book, with its price. The card says "3 left" (a list row says "3 available"); the panel says "3 available". Switch back to Mooney's Manager. |
| 3.15 | In "Books", search for the new title. Click it. | "FR14: the manager updates a book's information, such as the number of copies." | Window "Edit book" with the current details. |
| 3.16 | Change "Copies available" to `7`. Click "Save changes". | "The number of available copies is updated." | "Saved: <title>". The row shows "7 copies". |
| 3.17 | Click the log-out icon ("Log out"). | "That covers FR11 to FR14." | Back on "Log in". |

## 5. Video 4: extra credit (reviews and ratings, account page, sales report)

These are beyond FR1 to FR14 (course section 6). **Before you record:** services running, demo data loaded. Mooney's open on "Log in". Mooney's Manager open on "Log in" in another window.

| Step | What to do | What to say | Expected result |
|---|---|---|---|
| 4.1 | Log in to Mooney's as `<new-user>`. Search opens as a list, because step 2.5 chose "Show as a list" and the app remembers it for this account. Click the "Show as covers" icon. Point at a book card that has a rating. | "Extra credit: books show their average rating from customer reviews." | The covers view. On the card, one star with the average and the number of reviews in brackets, for example "4.3 (12)". Opening the book (4.2) shows five stars and "4.3 · 12 reviews". |
| 4.2 | Click a book that `<new-user>` has not reviewed. Scroll the panel to "Reviews". | "Each book shows its reviews, newest first." | "Reviews", the other customers' reviews with name, date, stars, and words, and the button "Write a review" (or "No reviews yet. Be the first."). |
| 4.3 | Click "Write a review". Click "Save" without choosing stars. | "A rating is required." | Window "Write a review". Under the stars: "Choose a rating from 1 to 5 stars". |
| 4.4 | Choose 4 stars. Type a short sentence in "What did you think? (optional)". Click "Save". | "Any logged-in customer may review a book, once." | "Your review of <title> is saved. Thank you!". The panel shows "Your review" first, with "Edit" and "Delete". The book's average and count change. |
| 4.5 | Click "Edit". Change to 5 stars. Click "Save". | "The writer can edit their review." | Window "Edit your review". After saving, "Your review" shows 5 stars. |
| 4.6 | Click "Delete". Then "Undo". | "And delete it, with Undo." | "Your review of <title> was deleted", then the review is back after Undo. |
| 4.7 | Close the panel. Click the `<new-user>` button ("Your account"). | "Extra credit: the account page, with the profile and the order history." | "Your account": "Profile" (Username, Email, Account "Customer") and "Preferences" ("Dark mode", "Open search as a list"). "Open search as a list" is off, because 4.1 switched back to covers. |
| 4.8 | Scroll to "Rentals due back" and "Your orders". | "Rented books show when they are due back. Every order I placed is listed." | The book rented in video 2 with "Due back in N days" and its date. The order from video 2 with its date, number of books, total, and "Paid" (marked by the manager in video 3). |
| 4.9 | Click that order. | "Each order opens its bill again." | Window "Order <number>" with the full bill and "Paid". Close it. |
| 4.10 | Back to search. Add one book with "Buy". "Your order (1)", "Place order". On the bill, click "Pay now". | "A pretend checkout: no card is asked for, and nothing is charged." | Window "Pay for order <number>", the total, and "This is a demonstration checkout. No card is needed and nothing is charged…". |
| 4.11 | Click "Pay $<total>". | "Paying only marks the order as paid." | "Order <number> is paid. Thank you!". The bill shows "Paid" and "Pay now" is gone. |
| 4.12 | Log out of Mooney's. Switch to Mooney's Manager. Log in as `manager1`. Click "Reports". | "Extra credit: the sales report, for managers only." | "Sales report", the period dates, and the period buttons "Today", "Last 7 days", "Last 30 days" (chosen), "This month", "All time". |
| 4.13 | Point at the four tiles. | "The report totals the period's orders." | "ORDERS" (with "N paid · M pending"), "REVENUE" (with the paid amount), "BOOKS SOLD", "BOOKS RENTED". |
| 4.14 | Point at a bar in "Sales by day". | "Sales by day, as a bar chart." | The bars with a date under each. The tooltip: "<date>: $<amount>, N orders". |
| 4.15 | Scroll to "Best sellers" and "Orders in this period". | "The best sellers, most copies first, and the orders behind the report." | Columns "#", "TITLE", "AUTHOR", "BOUGHT", "RENTED", "COPIES", "REVENUE". Then the orders list, newest first; the order paid in 4.11 is at the top. |
| 4.16 | Click "Today", then "All time". | "The period can be changed." | The tiles, the chart, and the lists change with the period. "Today" shows only orders placed today, including the one from 4.10 (and video 2's, if it was recorded today; demo or practice orders dated today may also appear). |
| 4.17 | Click "Log out". | "That covers the extra credit." | Back on "Log in". |

## 6. How to record on Windows

Both tools are built into Windows 11. Nothing needs to be installed.

| Tool | How | Notes |
|---|---|---|
| **Snipping Tool** (recommended) | Open Snipping Tool, choose the video camera ("Record"), click "New", drag over the whole screen, turn on the microphone in the bar, click "Start". Stop with the stop button. | Records the whole screen, so switching between the apps, File Explorer, and the browser is all in one video. Save the MP4 (it is also kept in `Videos\Screen Recordings`). |
| **Xbox Game Bar** | `Win + Alt + R` starts and stops recording. `Win + G` opens the bar, where the microphone can be turned on. | Records **one app window only**. It does not record File Explorer or the desktop, and stops following you when you switch apps. Fine for video 1; not for videos 2 to 4. |

Tips:

- Record at 1920 x 1080. Select the whole screen, not a smaller area, so the video is 1080p.
- Do one practice run of each video without recording. Then record in one take; a small mistake can stay if you say what happened.
- Speak slowly. Wait a second on each expected result so the viewer can read it.
- Keep each video between 3 and 6 minutes. If a video runs long, cut steps 3.6, 3.11, or 4.16 first; never cut a step that is the only proof of an FR (see section 8).
- Watch each recording once before uploading. Check that no password, `services/.env`, or private email is visible.

## 7. Upload to YouTube and add the links

1. Go to YouTube Studio, "Create", "Upload videos", and choose the MP4.
2. Title: `Mooney's bookstore, UAT video <n>: <topic>` (for example `UAT video 2: shopping and the bill (FR4-FR10)`).
3. Visibility: **Unlisted**. Anyone with the link can watch; it is not listed in search.
4. Paste the chapters into the description (template below). YouTube makes chapters only if the first time is `00:00`, there are at least three, and each is at least 10 seconds long.
5. After it has processed, open the link in a private browser window to check that it plays without signing in.

Description template (change the times to the real ones in your recording):

```text
Mooney's online bookstore (CSCE310 course project): user acceptance test, video 2 of 4.
Requirements FR4 to FR10.

00:00 Introduction
00:15 FR4 Search by title and author
01:00 FR5 Results as a list (title, author, price)
01:20 FR6 Selecting books
02:00 FR7 Buy and rent in one order
02:50 FR8 The bill
03:30 FR9 The bill saved as an HTML file
04:00 FR10 The bill emailed to the customer
04:40 End
```

Chapters for the other videos:

| Video | Chapters |
|---|---|
| 1 | Introduction · FR3 Create an account (and refused input) · FR1 Log in (and wrong password) · FR2 Staying logged in, logging out · Manager refused in the customer app |
| 3 | Introduction · FR11 Separate manager app (customer refused) · FR12 All purchase orders · FR13 Select an order · FR9 Print the saved bill · FR13 Mark as paid · FR14 Add a book (and refused input) · FR14 Update the copies |
| 4 | Introduction · Ratings on the books · Reviews: write, edit, delete · Account page and order history · Pretend checkout · Sales report |

Then paste each link into the `"url"` field of its entry in `docs/07-report/video-links.json`. The file already has the four entries, in video order; leave `"title"` and `"covers"` as they are. A url must start with `https://`, or the report shows "link to be added". The file is a list, one object per video:

```json
[
  {
    "title": "Accounts: register, log in, stay logged in, log out",
    "covers": "FR1, FR2, FR3",
    "url": "https://youtu.be/..."
  },
  ...
]
```

Then rebuild the report (from the repo root). It writes both `docs/07-report/report.html` and `docs/07-report/report.pdf`:

```text
python tools/report/build_report.py
```

Open `report.html` and `report.pdf` and check in both that each link is there and opens the right video.

## 8. Final checklist: every requirement is in a video

| Requirement | Video | Steps |
|---|---|---|
| FR1 Log in with username and password | 1 | 1.7 (wrong password refused), 1.8, 1.9 |
| FR2 Logged in until logging out | 1 | 1.10, 1.11 |
| FR3 Create an account (valid email, hashed password) | 1 | 1.2 to 1.6 (refused input in 1.3 to 1.5) |
| FR4 Search by keyword in title and author | 2 | 2.2 (author), 2.3 (title), 2.4 (no match) |
| FR5 Results list with title, author, price | 2 | 2.5 |
| FR6 Select one or more books | 2 | 2.6 to 2.9 |
| FR7 Buy and/or rent in a single order | 2 | 2.8 to 2.11 |
| FR8 Detailed bill: order ID, items, prices, total | 2 | 2.12 (again in 3.7 and 4.9) |
| FR9 Bill saved as an HTML file | 2, 3 | 2.14, 3.8 |
| FR10 Bill emailed to the customer | 2 | 2.13, 2.15 |
| FR11 Separate, secure management interface | 3 (and 1) | 3.1 to 3.4 (customer refused in 3.2), 1.12 (manager refused in the customer app) |
| FR12 Manager views all purchase orders | 3 | 3.5, 3.6 |
| FR13 Manager updates payment status | 3 | 3.7, 3.9 to 3.11 |
| FR14 Manager adds books and updates them (copies) | 3 | 3.12 to 3.16 (refused input in 3.12, 3.13) |
| Extra: reviews and ratings | 4 | 4.1 to 4.6 |
| Extra: account page with order history | 4 | 4.7 to 4.11 |
| Extra: sales report | 4 | 4.12 to 4.16 |

Before submitting, tick each:

- [ ] Four videos uploaded as Unlisted, each with chapters.
- [ ] Each link opens in a private window without signing in.
- [ ] No password, Gmail app password, or `services/.env` is visible in any video.
- [ ] All four links are in `docs/07-report/video-links.json`, and `python tools/report/build_report.py` has been run.
- [ ] Every row of the table above can be found at its step in the video.
