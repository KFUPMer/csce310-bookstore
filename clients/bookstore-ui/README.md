# bookstore_ui

The shared look of the two bookstore desktop apps, so they cannot drift apart.

| File | What it holds |
|---|---|
| `lib/src/tokens.dart` | Colors (light and dark), spacing, corner radii, motion timings, typefaces |
| `lib/src/theme.dart` | The Flutter theme built from the tokens |
| `lib/src/glass.dart` | Translucent blurred panels |
| `lib/src/book_cover.dart` | Book covers, including the generated one for books without an image |
| `lib/src/app_button.dart` | Buttons and icon buttons |
| `lib/src/smooth_scroll.dart` | Animated mouse-wheel scrolling |
| `lib/src/status_chip.dart` | Icon-and-word status labels |
| `fonts/` | Inter and Source Serif 4, with their SIL Open Font License files. Sources and versions: [REFERENCES.md](../../REFERENCES.md) |

The reasoning behind every value is in [docs/02-design/style-guide.md](../../docs/02-design/style-guide.md).
