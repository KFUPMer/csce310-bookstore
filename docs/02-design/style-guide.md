# Phase 2 — Visual style guide

> Status: **approved on 2026-11-13.** This is the style of both apps. It was judged from a working preview of one screen (the book catalog); how the motion feels is tuned while the screens are built in M4.

## The brief

In the project owner's words, turned into rules:

| Asked for | Rule |
|---|---|
| "As smooth as iOS and Apple UI, with glossy effects" | Floating translucent panels with blur ("glass"), soft shadows, rounded corners, short decelerating animations, a sheen on book covers |
| "Not colorful; the only thing that adds color is the books" | The whole interface is warm neutrals. Book covers are the only saturated color on screen |
| "Simple cozy colors that don't hurt the eye" | Off-white paper and warm near-black instead of pure white and pure black, in both modes |
| "Light and dark mode" | Two palettes with the same structure; one button switches between them |
| "Accessible for color-blind users" | Meaning is never carried by color alone; every text color passes WCAG AA contrast |
| "Books displayed smoothly, easy to check and search" | Cover grid with live search on title and author, a list view, and a detail panel that slides in |
| "Cover all of Nielsen's heuristics" | See [the table below](#nielsens-10-usability-heuristics) |

## Preview

The catalog screen of the customer app, running on sample data. These are real screenshots of the Flutter app, not mock-ups.

**Light**

![Catalog, light mode](ui/catalog-light.png)

**Light, with a book selected**

![Catalog with detail panel, light mode](ui/catalog-light-detail.png)

**Dark**

![Catalog, dark mode](ui/catalog-dark.png)

**Dark, with a book selected**

![Catalog with detail panel, dark mode](ui/catalog-dark-detail.png)

**List view with a search** (title, author, price in columns: FR5)

![List view, searching for java](ui/catalog-light-list-search.png)

**Nothing found**

![Empty search result, dark mode](ui/catalog-dark-empty.png)

To run it: open the repository in VS Code, choose "Customer app" in Run and Debug, press F5. The screen is `SearchScreen` in `clients/customer-app/lib/screens/search_screen.dart`.

## Mooney's: the sign, the shelves, and real covers (M5)

Added at the owner's request after M4, from a bookstore website they liked and the shop sign of **Mooney's** in the series *You*.

- **The sign.** MOONEY'S in gold capitals on deep green, with wide letter spacing and a gold-leaf shading, like a painted shopfront. Small in the top bar of both apps; large on the login screens, with the line "BOOKSELLERS · EST. 2026". It is the one colored thing besides the covers, so the rule "only the books bring color" still holds. It looks the same in light and dark mode, as a painted sign would.
- **The shelves.** All, Fiction, Nonfiction, Kids, Science, Technology, as a row under the sign, like a bookshop's sections. The chosen one is bold with a short accent underline: weight and line, not color alone (color-blind users). Tab and Enter work.
- **Real covers.** Every book shows its real cover photo. The drawn cover shows first and the photo fades in over it (Motion.base), so a slot is never empty. Without internet the drawn cover stays.

## Reviews and the sales report (v1.1.0)

Added for the extra credit (course section 6). Nothing new brings color: the covers and the sign stay the only colored things.

- **Stars.** A rating is drawn in the neutral ink color, never gold or yellow. A star is filled, half filled, or outlined, so the rating is told by shape, not by color, and color-blind users read it the same way. The number is written next to it ("4.0 · 3 reviews"), and a screen reader hears one sentence ("Rated 4.3 out of 5 from 12 reviews"). A card has room for one star and "4.0 (3)" only; the detail panel shows all five.
- **Choosing stars.** The five stars of the review dialog are five buttons, each with a tooltip ("1 star" to "5 stars"). Tab reaches them, Enter or Space chooses, and the pointer previews a choice on hover. The choice is also written in words ("3 of 5 stars", or "No stars chosen"). Saving without stars puts the problem under them, with an icon, like every other field.
- **Reviews in the detail panel.** "Your review" comes first, in a card with Edit and Delete; Delete offers Undo in a toast. The other reviews follow, newest first, each with the name, the date, the stars, and the text.
- **The sales report.** Period buttons at the top; the chosen one is filled and has a check, so it is not told by color alone. Four tiles give the numbers in the serif of the headings (orders, revenue, books sold, books rented), each with a line of detail under it. Sales by day are bars in the ink color with the day under each bar and the amount over it when the bar is wide enough (at least 64 px), so the chart is read from its words; at most the last 31 days with orders are drawn, and more than fit scroll sideways; pointing at a bar shows the date, the amount, and the number of orders. The best sellers are a plain numbered table, and the period's orders follow, with the same Paid/Pending chip as the Orders tab.

**Reviews**, in the customer app: the rating on each card, and the detail panel's Reviews section.

![Reviews and ratings, light](ui/customer-reviews-light.png)

**Sales report**, in the manager app's new Reports tab.

![Sales report, light](ui/manager-reports-light.png)

![Sales report, dark](ui/manager-reports-dark.png)

## Customer app as built (M4)

Every screen of the customer app, in the approved style. Drawn by Flutter from the app's real widgets, with the real typefaces, on the 81 sample books, with their real cover photos, and stand-in services, at 1440 x 900 (`test/screenshots_test.dart`). They are not captures of the running window; that the app works against the real services was checked separately.

**Log in**, and **a wrong password** in dark mode. The sign and the fan of covers are the only color on the screen.

![Log in, light](ui/customer-login-light.png)

![Log in with an error, dark](ui/customer-login-dark-error.png)

**Create an account**: each problem under its field, with an icon, after the first attempt.

![Create an account with problems, dark](ui/customer-register-dark-errors.png)

**Search**, and a book opened after renting it. The toast says what happened and offers Undo.

![Search, light](ui/customer-search-light.png)

![Search with the detail panel, light](ui/customer-search-light-detail.png)

**A search in the list view** (title, author, price in columns: FR5), dark.

![Search results as a list, dark](ui/customer-search-dark-list.png)

**Your order**: buy or rent with both prices shown, the due date of a rented book, and the total.

![Your order, light](ui/customer-order-light.png)

**The bill**: the same parts, in the same order, as the HTML bill that is saved and emailed.

![Bill, light](ui/customer-bill-light.png)

**Your account**, opened from the customer's name in the top bar: profile, preferences, rentals due back, and orders. A late rental is told by a warning icon and the words "Was due back", not by its color alone. Paid and pending orders have the same height, so the list reads as one column.

![Your account, light](ui/customer-account-light.png)

**The pretend checkout.** It says plainly that it is a demonstration and charges nothing. One main button, with the amount on it.

![Pay for an order, light](ui/customer-pay-light.png)

**After paying**, dark mode switched on from the preferences, with the toast that confirms it.

![Your account after paying, dark](ui/customer-account-dark-paid.png)

## Management app as built (M4)

The same style, the same shared widgets. Drawn the same way as the customer app's screenshots, on sample orders and the 81 sample books.

**Log in**: the same form as the customer app, for managers only.

![Manager log in, light](ui/manager-login-light.png)

**Orders**: newest first, with how many wait for payment, a filter with counts, and "Mark as paid" on each pending row. Paid and Pending are told by an icon and a word, filled or outlined, never by color alone.

![Orders, light](ui/manager-orders-light.png)

![Orders, dark](ui/manager-orders-dark.png)

**An order**: its bill, the same `BillView` the customer sees, with the current payment status, Mark as paid, and Print.

![An order's bill, light](ui/manager-order-bill-light.png)

**Books**, and **editing a book** with a problem under its field.

![Books, light](ui/manager-books-light.png)

![Edit book with a problem, light](ui/manager-book-form-light-error.png)

## Color

Warm neutrals only. Every value lives in one file: [tokens.dart](../../clients/bookstore-ui/lib/src/tokens.dart).

| Role | Light | Dark | Used for |
|---|---|---|---|
| Background | `#F4F0E9` | `#151311` | The page |
| Surface | `#FFFCF7` | `#201D1A` | Selected cards, fields |
| Glass | Surface at 70%, over a blur | `#262220` at 60%, over a blur | Top bar, detail panel, toasts |
| Text | `#1F1B17` | `#F2EDE6` | Main text |
| Text, secondary | `#62594F` | `#B3A99D` | Authors, descriptions |
| Text, tertiary | `#746A5F` | `#8C8378` | Hints, small labels |
| Hairline | `#E2DBD0` | `#37322C` | Thin borders and separators |
| Ink | `#1F1B17` | `#F2EDE6` | The main button of a screen |
| Accent | `#8F4721` | `#E5A078` | Focus ring, selection outline. Used sparingly |
| Danger | `#9E2A1F` | `#F0A79C` | Error text, always with an icon |
| Sign green | `#1D3B31` to `#2A5141` | the same | The Mooney's sign only |
| Sign gold | `#D9B871`, shaded `#F2DDA2` to `#AE8840` | the same | The letters on the sign. The main gold on the dark green is 6.4 : 1; the gold-leaf shading goes lower, down to about 2.7 : 1 (deepest gold on the lighter green). WCAG 1.4.3 does not apply to a logo, and the name is also in the window title and read out by screen readers |

**Book covers** are the color. A book with a cover image shows it. A book without one gets a generated cover: a muted color picked from its title (so the same book always looks the same), the title in a serif, and a sheen.

### Contrast (WCAG AA needs 4.5 : 1 for text)

Lowest ratio of each text color against the two backgrounds it sits on:

| Color | Light | Dark |
|---|---|---|
| Text | 15.1 | 14.4 |
| Text, secondary | 6.0 | 7.3 |
| Text, tertiary | 4.7 | 4.5 |
| Accent | 6.0 | 7.7 |
| Danger | 6.6 | 8.6 |
| Text on the main button | 16.7 | 15.4 |

## Type

| Use | Typeface | Why |
|---|---|---|
| Interface text | **Inter** | Open source and designed for screens; the closest free equivalent to Apple's SF Pro |
| Headings and titles on generated covers | **Source Serif 4** | A bookish serif, in the role Apple gives its "New York" typeface |

Apple's own SF Pro was considered and cannot be used: its license only allows it in software that runs on Apple platforms, and these are Windows apps. Inter and Source Serif 4 are under the SIL Open Font License, which allows bundling. Both are included in the shared package, with their license files, so the apps look the same on any machine.

| Style | Size | Weight |
|---|---|---|
| Page heading | 34 | Serif, semibold |
| Panel heading | 24 | Serif, semibold |
| Card title | 13.5 | Semibold |
| Body | 14–15 | Regular |
| Small text | 12.5 | Regular |
| Label | 11 | Semibold, wide spacing |

## Shape, depth, and glass

- **Spacing** uses one scale: 4, 8, 12, 16, 24, 32, 48.
- **Corners:** covers 6, controls 10, cards 16, panels 22, search field and chips fully round.
- **Glass:** panels that float above content are translucent with a blur behind them, a thin border, and a faint light edge on top. Content scrolls underneath, so the covers tint the bar as they pass.
- **Shadows** are large, soft, and low-contrast. No hard drop shadows.
- **No ripple effects.** Feedback is a quiet fill and a small change of size.

## Motion

| Speed | Time | Used for |
|---|---|---|
| Fast | 140 ms | Hover, press, focus |
| Base | 240 ms | Cards lifting, toasts, wheel scrolling |
| Slow | 380 ms | The detail panel, switching light and dark |

Everything decelerates into place (ease-out). Nothing bounces or loops.

- **Covers lift** slightly under the pointer.
- **The detail panel slides in** and the grid makes room for it instead of being covered.
- **Mouse-wheel scrolling glides.** Flutter moves a page in steps by default; the apps animate it instead.

## Accessibility

**Color-blind users**

- No state is told by color alone. Availability, "in your order", errors, and payment status all use an icon and a word.
- The interface is nearly gray-scale, so it looks almost the same with any type of color blindness.
- Generated cover colors are decoration only: the title and author are always in text.
- The accent and danger colors are both reddish-brown and can look alike to some users. That is why the accent is only an outline and errors always carry an icon and a sentence.

**Everyone else**

- Contrast passes WCAG AA for all text, in both modes.
- Everything works from the keyboard: Tab moves between controls, Enter activates, and focus is shown with a 2px outline.
- Every icon-only button has a tooltip, which is also its name for screen readers.
- Text sizes are never below 11.

## Nielsen's 10 usability heuristics

| # | Heuristic | How the design meets it | In the preview? |
|---|---|---|---|
| 1 | Visibility of system status | The heading always says what is shown ("3 of 15 books match"). Buttons show a spinner while a request runs. A toast confirms each action. The order button shows its item count | Yes, including spinners while the services answer |
| 2 | Match between system and the real world | Books are shown as books, with covers. Plain words: "Buy", "Rent for 7 days", "Only 2 left". No codes or technical terms | Yes |
| 3 | User control and freedom | Every toast has Undo. Esc closes the panel, then clears the search. The order can be changed until it is placed | Undo and Esc: yes |
| 4 | Consistency and standards | One shared theme package for both apps: same buttons, spacing, and words everywhere. Standard shortcuts (Ctrl+F, Esc, Tab, Enter) | Yes |
| 5 | Error prevention | A book that cannot be ordered has disabled buttons and says why. A book cannot be added twice. Buttons are disabled while a request runs, so nothing is sent twice | Yes |
| 6 | Recognition rather than recall | Price, availability, and "in your order" are on every card. The rent price is shown on the button, not left to be calculated | Yes |
| 7 | Flexibility and efficiency of use | Covers view for browsing, list view for scanning. Search filters as you type. Keyboard shortcuts for frequent actions | Yes |
| 8 | Aesthetic and minimalist design | Neutral interface; only the covers have color. Each screen has one main button. Details appear only when a book is selected | Yes |
| 9 | Help users recognize, diagnose, and recover from errors | Messages say what happened and what to do, in plain words, next to where it happened. "No books match" suggests a fix and offers a button | Yes: field problems, wrong password, a service not answering ("Try again"), a book that sold out while ordering |
| 10 | Help and documentation | Tooltips on every icon. Hints inside the search field. The renting rule is explained where the choice is made | Yes |

## What changes in the earlier design

- **The search screen is a cover grid, not a table.** The [wireframe](ui-design.md) showed a table; it becomes the optional list view. FR5 (title, author, price in a clear list) is met by both views.
- **Books get an optional cover image.** A new optional field `coverUrl` on a book. Without it, the generated cover is used.
- **One shared package**, [clients/bookstore-ui](../../clients/bookstore-ui), holds the theme and common widgets for both apps.

## Not checked yet

- **How the motion feels.** Screenshots cannot show it. Scrolling, hover, and the panel animation need to be tried by hand.
- **Trackpad scrolling.** Written, but only testable on a real trackpad.
- **Screen readers.** Labels are in place; they have not been tested with Windows Narrator.
- **A color-blindness simulation** of the screenshots has not been run.
- **Both apps' real windows** have been run by the owner and work; how the motion feels has not been commented on yet.
