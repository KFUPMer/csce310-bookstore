# bookstore_ui

Everything the two bookstore desktop apps share, so they cannot drift apart: the look, and since M4 the way they talk to the services.

| File | What it holds |
|---|---|
| `lib/src/tokens.dart` | Colors (light and dark), spacing, corner radii, motion timings, typefaces |
| `lib/src/theme.dart` | The Flutter theme built from the tokens |
| `lib/src/glass.dart` | Translucent blurred panels |
| `lib/src/book_cover.dart` | Book covers, including the generated one for books without an image |
| `lib/src/app_button.dart` | Buttons and icon buttons |
| `lib/src/smooth_scroll.dart` | Animated mouse-wheel scrolling |
| `lib/src/status_chip.dart` | Icon-and-word status labels |
| `lib/src/format.dart` | Money ($1,234.50, rounded like the bill) and dates |
| `lib/src/app_text_field.dart` | Labelled text fields (one line, or several with `lines`) with their problem written under them; error messages |
| `lib/src/stars.dart` | `RatingStars` (a book's rating, full or compact as on a card) and `StarPicker` (choosing 1 to 5 stars, by mouse or keyboard) |
| `lib/src/toast.dart` | The toast with Undo, and the page change used between screens |
| `lib/src/bill_view.dart` | The bill of an order, drawn in the app |
| `lib/src/auth_layout.dart` | The layout of the log-in and create-account screens |
| `lib/src/login_form.dart` | The log-in form, letting in one role only; a neutral info note |
| `lib/src/search_field.dart` | The round search field |
| `lib/src/mooneys_sign.dart` | The store's sign, MOONEY'S in gold on deep green |
| `lib/src/api/` | `ApiClient` (requests, readable errors), `Session`, `UserApi`, `BookApi` (including a book's reviews, and saving or deleting one's own) |
| `lib/src/models/` | `Book` (with its shelf and rating), `Review`, `Order`, `PlacedItem`, `ItemType`, the five shelves, and the renting rule |
| `fonts/` | Inter and Source Serif 4, with their SIL Open Font License files. Sources and versions: [REFERENCES.md](../../REFERENCES.md) |

The reasoning behind every visual value is in [docs/02-design/style-guide.md](../../docs/02-design/style-guide.md).

```bash
flutter test
```

40 tests: the book's rent price, money, and rating, a review and an order read from JSON, the cover colors, the stars and the star picker, the multi-line text field, and the service client (including the review calls) against a small real web server.
