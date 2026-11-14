# Desktop clients

Two separate Flutter desktop apps, written in Dart.

| Folder | For | Does |
|---|---|---|
| `customer-app/` | Customers | Log in, register, search books, select and order them, see the bill |
| `management-app/` | Managers | View orders, update payment status, add and update books |

Both are still the empty starter project that Flutter generates; the real screens are built in milestone M4.

Design: [UI](../docs/02-design/ui-design.md), [class diagrams](../docs/02-design/class-diagrams.md).

## Running an app

**In VS Code:** open the Run and Debug panel (Ctrl+Shift+D), pick "Customer app" or "Management app", and press F5. Saving a file while it runs updates the window immediately (hot reload).

**From a terminal:**

```bash
cd clients/customer-app
```

```bash
flutter run -d windows
```

## One-time setup on a new machine

1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install/windows/desktop) and add its `bin` folder to PATH.
2. Install Visual Studio 2022 Build Tools with the "Desktop development with C++" workload (Flutter needs it to compile Windows apps).
3. In VS Code, install the "Flutter" extension (it brings the Dart extension with it).
4. Run `flutter doctor` and fix anything it marks with a cross for Windows.
