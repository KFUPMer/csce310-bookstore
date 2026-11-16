# Diagram generators

The scripts that produce the `.drawio` files in `docs/02-design/diagrams`. They place boxes and lines by coordinates, so a diagram can be regenerated when the design changes.

They were written quickly while the diagrams were being made, and are kept as they are. The `.drawio` files can also be edited by hand in draw.io; if you do that, do not regenerate that diagram afterwards, or the hand edits are lost.

| Script | Produces |
|---|---|
| `flutter_cls.py` | `class-customer-app`, `class-manager-app`. Also the drawing helpers (`cls`, `edge`, `note`, `write`) the scripts below import |
| `ui_cls.py` | `class-bookstore-ui` |
| `user_cls.py` | `class-user-service` |
| `book_cls.py` | `class-book-service` |
| `order_cls.py` | `class-order-service` |
| `flows.py` | The four sequence diagrams, `activity-login`, `activity-manager-payment`, and the two wireframes |
| `uml.py` | `use-case`, `activity-place-order`, `state-machine`, `component`, `object`, `profile`, `class-services` |

## Use

From this folder, give the output folder as the argument:

```bash
python book_cls.py ../../docs/02-design/diagrams
```

Then export the image with draw.io Desktop, from `docs/02-design/diagrams`:

```bash
"%LOCALAPPDATA%\Programs\draw.io\draw.io.exe" -x -f png -s 2 -b 20 -o class-book-service.png class-book-service.drawio
```

**Open the image and look at it before committing.** Lines through boxes and clipped text only show in the image (problem P-011).

## Known faults

- **`uml.py` still writes three diagrams that were removed** on request: `deployment`, `package`, `composite-structure`. Delete those three files after running it. It also writes an old colored `sequence-place-order`; run `flows.py` after it to put the right one back.
- Importing `flutter_cls` rewrites the two app class diagrams. The result is identical, so `git status` should show no change to them.
- Check `git status` after any run: only the diagram you meant to change should have changed.

## Adding a diagram for a new service

Copy `book_cls.py`, change the classes and positions, and add a row to the table above and to `docs/02-design/diagrams/README.md`.
