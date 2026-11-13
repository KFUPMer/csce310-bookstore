# Design diagrams

Every design diagram in this project is made in [draw.io](https://www.drawio.com/) (diagrams.net).

## Rule

1. The diagram is drawn and edited in draw.io and saved here as `<name>.drawio` — this is the source.
2. An image of it is exported as `<name>.png` into this same folder.
3. The design document embeds the image: `![Architecture](diagrams/architecture.png)`.
4. Source and image are committed together, so GitHub always shows the current design and the history shows how it changed.

When a diagram changes, update the `.drawio` file, export the image again, and commit both.

## Diagrams

| Diagram | Source | Image | Used in |
|---|---|---|---|
| System architecture | `architecture.drawio` | `architecture.png` | [architecture.md](../architecture.md) |
| Database ER / document model | `database-er.drawio` | `database-er.png` | [database-design.md](../database-design.md) |
| Use case diagram | planned (M2) | — | — |
| Sequence: place an order | planned (M2) | — | — |
| Class diagram, customer app | `class-customer-app.drawio` | `class-customer-app.png` | [class-diagrams.md](../class-diagrams.md) |
| Class diagram, manager app | `class-manager-app.drawio` | `class-manager-app.png` | [class-diagrams.md](../class-diagrams.md) |
| Class diagrams, backend services | planned (M2) | — | — |
| UI wireframes, customer app | planned (M2) | — | — |
| UI wireframes, management app | planned (M2) | — | — |

## Exporting an image

With draw.io Desktop installed, from this folder:

```bash
draw.io -x -f png -s 2 -b 20 -o architecture.png architecture.drawio
```

`-s 2` doubles the resolution and `-b 20` adds a small border. In the app the same thing is File → Export as → PNG.
