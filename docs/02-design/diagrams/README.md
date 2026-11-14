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
| System architecture (overview) | `architecture.drawio` | `architecture.png` | [architecture.md](../architecture.md) |
| Database ER / document model | `database-er.drawio` | `database-er.png` | [database-design.md](../database-design.md) |
| Class diagram, customer app | `class-customer-app.drawio` | `class-customer-app.png` | [class-diagrams.md](../class-diagrams.md) |
| Class diagram, manager app | `class-manager-app.drawio` | `class-manager-app.png` | [class-diagrams.md](../class-diagrams.md) |
| Class diagram, shared UI package | `class-bookstore-ui.drawio` | `class-bookstore-ui.png` | [class-diagrams.md](../class-diagrams.md) |
| Class diagram, backend services | `class-services.drawio` | `class-services.png` | [uml-diagrams.md](../uml-diagrams.md) |
| Object diagram | `object.drawio` | `object.png` | [uml-diagrams.md](../uml-diagrams.md) |
| Component diagram | `component.drawio` | `component.png` | [uml-diagrams.md](../uml-diagrams.md) |
| Profile diagram | `profile.drawio` | `profile.png` | [uml-diagrams.md](../uml-diagrams.md) |
| Use case diagram | `use-case.drawio` | `use-case.png` | [use-cases.md](../use-cases.md) |
| Sequence diagram: place an order | `sequence-place-order.drawio` | `sequence-place-order.png` | [uml-diagrams.md](../uml-diagrams.md) |
| Activity diagram: place an order | `activity-place-order.drawio` | `activity-place-order.png` | [uml-diagrams.md](../uml-diagrams.md) |
| State machine diagrams | `state-machine.drawio` | `state-machine.png` | [uml-diagrams.md](../uml-diagrams.md) |
| Sequence diagram: log in | `sequence-login.drawio` | `sequence-login.png` | [uml-diagrams.md](../uml-diagrams.md) |
| Sequence diagram: register | `sequence-register.drawio` | `sequence-register.png` | [uml-diagrams.md](../uml-diagrams.md) |
| Sequence diagram: update payment status | `sequence-update-payment.drawio` | `sequence-update-payment.png` | [uml-diagrams.md](../uml-diagrams.md) |
| Activity diagram: log in and register | `activity-login.drawio` | `activity-login.png` | [uml-diagrams.md](../uml-diagrams.md) |
| Activity diagram: manager updates payment | `activity-manager-payment.drawio` | `activity-manager-payment.png` | [uml-diagrams.md](../uml-diagrams.md) |
| UI wireframes, customer app | `wireframes-customer-app.drawio` | `wireframes-customer-app.png` | [ui-design.md](../ui-design.md) |
| UI wireframes, manager app | `wireframes-manager-app.drawio` | `wireframes-manager-app.png` | [ui-design.md](../ui-design.md) |

## Exporting an image

With draw.io Desktop installed, from this folder:

```bash
draw.io -x -f png -s 2 -b 20 -o architecture.png architecture.drawio
```

`-s 2` doubles the resolution and `-b 20` adds a small border. In the app the same thing is File → Export as → PNG.
